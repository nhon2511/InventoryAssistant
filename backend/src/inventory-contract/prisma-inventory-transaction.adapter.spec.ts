import { Prisma } from '@prisma/client';
import { describe, expect, it, vi } from 'vitest';
import type { PrismaService } from '../prisma/prisma.service.js';
import {
  executeMovementContract,
  requestFingerprint,
  type IdempotencyRecord,
  type MovementCommand,
} from './inventory-command.contract.js';
import {
  isRetryableTransactionError,
  PrismaInventoryTransactionAdapter,
} from './prisma-inventory-transaction.adapter.js';

const now = new Date('2026-11-13T00:00:00Z');
const command: MovementCommand = {
  transactionType: 'OUTBOUND',
  scopeId: '00000000-0000-4000-8000-000000000001',
  key: 'request-1',
  method: 'POST',
  path: '/inventory/movements',
  body: { quantity: 2 },
  inventoryItemId: '00000000-0000-4000-8000-000000000002',
  productId: '00000000-0000-4000-8000-000000000003',
  locationId: '00000000-0000-4000-8000-000000000004',
  actorId: '00000000-0000-4000-8000-000000000005',
  delta: -2,
  now,
  expiresAt: new Date('2026-11-14T00:00:00Z'),
};

function fixture(existing?: IdempotencyRecord) {
  const statements: string[] = [];
  const queryRaw = vi.fn(async (strings: TemplateStringsArray) => {
    const sql = strings.join('?');
    statements.push(sql);
    if (sql.includes('set_config')) return [{ set_config: '3s' }];
    if (sql.includes('INSERT INTO public.idempotency_keys')) {
      return existing ? [] : [{ scope_id: command.scopeId }];
    }
    if (sql.includes('FROM public.idempotency_keys')) return existing ? [existing] : [];
    if (sql.includes('FROM public.inventory_items')) {
      return [{
        id: command.inventoryItemId,
        productId: command.productId,
        locationId: command.locationId,
        quantityOnHand: 7,
        quantityReserved: 2,
      }];
    }
    throw new Error('Unexpected mocked SQL');
  });
  const updateInventory = vi.fn(async () => ({ count: 1 }));
  const createLedger = vi.fn(async () => ({ id: 'ledger-1' }));
  const completeKey = vi.fn(async () => ({ count: 1 }));
  const tx = {
    $queryRaw: queryRaw,
    inventoryItem: { updateMany: updateInventory },
    stockLedger: { create: createLedger },
    idempotencyKey: { updateMany: completeKey },
  };
  const run = vi.fn(async (work: (transaction: typeof tx) => Promise<unknown>) => work(tx));
  const adapter = new PrismaInventoryTransactionAdapter(
    { $transaction: run } as unknown as PrismaService,
    async () => {},
  );
  return { adapter, run, queryRaw, updateInventory, createLedger, completeKey, statements };
}

describe('Prisma transaction adapter with SQL-shaped mocks only', () => {
  it('runs claim, parameterized row lock, stock update, ledger and completion on one tx', async () => {
    const f = fixture();
    await expect(executeMovementContract(f.adapter, command)).resolves.toEqual({
      kind: 'applied', balance: 5,
    });
    expect(f.run).toHaveBeenCalledTimes(1);
    expect(f.run.mock.calls[0][1]).toMatchObject({
      maxWait: 2000, timeout: 10000,
      isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
    });
    expect(f.statements.some((sql) => sql.includes('FROM public.inventory_items') && sql.includes('FOR UPDATE'))).toBe(true);
    expect(f.statements.some((sql) => sql.includes('ON CONFLICT (scope_id, key) DO NOTHING'))).toBe(true);
    expect(f.updateInventory).toHaveBeenCalledWith({
      where: { id: command.inventoryItemId }, data: { quantityOnHand: 5 },
    });
    expect(f.createLedger).toHaveBeenCalledWith({
      data: expect.objectContaining({
        transactionType: 'OUTBOUND', delta: -2, balance: 5,
        inventoryItemId: command.inventoryItemId, createdBy: command.actorId,
      }),
    });
    expect(f.completeKey).toHaveBeenCalledTimes(1);
    // Values are separate tagged-template arguments, never SQL concatenation.
    const insertCall = f.queryRaw.mock.calls.find((call) =>
      call[0].join('?').includes('INSERT INTO public.idempotency_keys'),
    );
    expect(insertCall?.[0].join('?')).not.toContain(command.key);
  });

  it('replays the same completed key and rejects a different hash without writes', async () => {
    const hash = requestFingerprint(command.method, command.path, command.body);
    const record: IdempotencyRecord = {
      httpMethod: command.method,
      requestPath: command.path,
      requestHash: hash,
      processingStatus: 'completed',
      statusCode: 200,
      response: { inventoryItemId: command.inventoryItemId, balance: 5 },
      expiresAt: command.expiresAt,
    };
    const f = fixture(record);
    await expect(executeMovementContract(f.adapter, command)).resolves.toMatchObject({
      kind: 'replay', statusCode: 200,
    });
    await expect(executeMovementContract(f.adapter, { ...command, body: { quantity: 3 } })).resolves.toEqual({ kind: 'conflict' });
    expect(f.statements.filter((sql) => sql.includes('FROM public.idempotency_keys') && sql.includes('FOR UPDATE'))).toHaveLength(2);
    expect(f.updateInventory).not.toHaveBeenCalled();
    expect(f.createLedger).not.toHaveBeenCalled();
  });

  it('propagates ledger errors before key completion', async () => {
    const f = fixture();
    f.createLedger.mockRejectedValueOnce(new Error('ledger failed'));
    await expect(executeMovementContract(f.adapter, command)).rejects.toThrow('ledger failed');
    expect(f.completeKey).not.toHaveBeenCalled();
    expect(f.run).toHaveBeenCalledTimes(1);
  });

  it('retries only bounded P2034 or known raw SQLSTATE errors', async () => {
    const conflict = new Prisma.PrismaClientKnownRequestError('write conflict', {
      code: 'P2034', clientVersion: '6.19.3',
    });
    const rawDeadlock = new Prisma.PrismaClientKnownRequestError('deadlock', {
      code: 'P2010', clientVersion: '6.19.3', meta: { code: '40P01' },
    });
    expect(isRetryableTransactionError(conflict)).toBe(true);
    expect(isRetryableTransactionError(rawDeadlock)).toBe(true);
    expect(isRetryableTransactionError(new Error('insufficient stock'))).toBe(false);
    const f = fixture();
    f.run.mockRejectedValueOnce(conflict).mockRejectedValueOnce(rawDeadlock);
    await expect(executeMovementContract(f.adapter, command)).resolves.toMatchObject({ kind: 'applied' });
    expect(f.run).toHaveBeenCalledTimes(3);
    const g = fixture();
    g.run.mockRejectedValue(conflict);
    await expect(executeMovementContract(g.adapter, command)).rejects.toBe(conflict);
    expect(g.run).toHaveBeenCalledTimes(3);
  });

  it('models two concurrent requests only with a fake uniqueness queue', async () => {
    const first = fixture();
    // This mock serializes the calls as a database unique-key wait would. It
    // does not prove PostgreSQL lock timing, isolation or pooler behavior.
    let releaseFirst: (() => void) | undefined;
    const gate = new Promise<void>((resolve) => { releaseFirst = resolve; });
    const originalRun = first.run.getMockImplementation();
    first.run.mockImplementationOnce(async (...args) => {
      await gate;
      return originalRun?.(...args);
    });
    const pending = executeMovementContract(first.adapter, command);
    const hash = requestFingerprint(command.method, command.path, command.body);
    const duplicate = fixture({
      httpMethod: command.method, requestPath: command.path, requestHash: hash,
      processingStatus: 'completed', statusCode: 200,
      response: { inventoryItemId: command.inventoryItemId, balance: 5 },
      expiresAt: command.expiresAt,
    });
    const replay = executeMovementContract(duplicate.adapter, command);
    releaseFirst?.();
    const results = await Promise.all([pending, replay]);
    expect(results.map((result) => result.kind).sort()).toEqual(['applied', 'replay']);
  });
});
