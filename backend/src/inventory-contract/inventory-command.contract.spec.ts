import { describe, expect, it } from 'vitest';
import {
  assertApproverRole,
  decideClaim,
  executeMovementContract,
  nextOnHand,
  requestFingerprint,
  type IdempotencyRecord,
  type InventoryTransactionPort,
  type InventoryTransactionRunner,
  type MovementCommand,
} from './inventory-command.contract.js';

const now = new Date('2026-11-13T00:00:00Z');
const expiresAt = new Date('2026-11-14T00:00:00Z');
const command: MovementCommand = {
  scopeId: 'scope-1',
  key: 'request-1',
  method: 'POST',
  path: '/inventory/movements',
  body: { reason: 'receiving', quantity: 3 },
  inventoryItemId: 'item-1',
  productId: 'product-1',
  locationId: 'location-1',
  delta: 3,
  actorId: 'actor-1',
  now,
  expiresAt,
};

class FakeRunner implements InventoryTransactionRunner {
  balance = 5;
  reserved = 2;
  productId = 'product-1';
  record: IdempotencyRecord | null = null;
  ledger: Array<{ delta: number; balance: number }> = [];
  calls: string[] = [];
  failAppend = false;

  async transaction<T>(work: (tx: InventoryTransactionPort) => Promise<T>): Promise<T> {
    let nextBalance = this.balance;
    let nextRecord = this.record;
    const nextLedger = [...this.ledger];
    const tx: InventoryTransactionPort = {
      claimOrLock: async (input) => {
        this.calls.push('claimOrLock');
        if (nextRecord) return nextRecord;
        nextRecord = {
          httpMethod: input.method,
          requestPath: input.path,
          requestHash: input.hash,
          processingStatus: 'processing',
          statusCode: null,
          response: null,
          expiresAt: input.expiresAt,
        };
        return null;
      },
      lockInventory: async (id) => {
        this.calls.push('lockInventory');
        return {
          id,
          productId: this.productId,
          locationId: 'location-1',
          quantityOnHand: nextBalance,
          quantityReserved: this.reserved,
        };
      },
      updateOnHand: async (_id, balance) => {
        this.calls.push('updateOnHand');
        nextBalance = balance;
      },
      appendLedger: async (input) => {
        this.calls.push('appendLedger');
        if (this.failAppend) throw new Error('ledger insert failed');
        nextLedger.push({ delta: input.delta, balance: input.balance });
      },
      completeClaim: async (input) => {
        this.calls.push('completeClaim');
        if (!nextRecord) throw new Error('claim missing');
        nextRecord = {
          ...nextRecord,
          processingStatus: 'completed',
          statusCode: input.statusCode,
          response: input.response,
        };
      },
    };
    const result = await work(tx);
    this.balance = nextBalance;
    this.record = nextRecord;
    this.ledger = nextLedger;
    return result;
  }
}

describe('offline inventory transaction contract', () => {
  it('hashes canonical JSON and detects changed request payload', () => {
    const a = requestFingerprint('POST', '/x', { a: 1, b: 2 });
    const b = requestFingerprint('POST', '/x', { b: 2, a: 1 });
    expect(a).toBe(b);
    expect(a).toMatch(/^[0-9a-f]{64}$/);
    expect(requestFingerprint('POST', '/x', { a: 2, b: 2 })).not.toBe(a);
  });

  it('distinguishes conflict, in-progress, replay and expired keys', () => {
    const hash = requestFingerprint(command.method, command.path, command.body);
    const record: IdempotencyRecord = {
      httpMethod: command.method,
      requestPath: command.path,
      requestHash: hash,
      processingStatus: 'processing',
      statusCode: null,
      response: null,
      expiresAt,
    };
    const request = { method: command.method, path: command.path, hash };
    expect(decideClaim(record, request, now).kind).toBe('in_progress');
    expect(decideClaim(record, { ...request, hash: 'different' }, now).kind).toBe('conflict');
    expect(
      decideClaim(
        { ...record, processingStatus: 'completed', statusCode: 200, response: { ok: true } },
        request,
        now,
      ),
    ).toEqual({ kind: 'replay', statusCode: 200, response: { ok: true } });
    expect(decideClaim(record, request, expiresAt).kind).toBe('expired');
  });

  it('enforces int4/nonnegative limits and approval roles', () => {
    expect(nextOnHand(5, -3)).toBe(2);
    expect(() => nextOnHand(1, -2)).toThrow();
    expect(() => nextOnHand(2147483647, 1)).toThrow();
    expect(() => nextOnHand(1, 0)).toThrow();
    expect(() => assertApproverRole('STAFF')).toThrow();
    expect(() => assertApproverRole('ADMIN')).not.toThrow();
    expect(() => assertApproverRole('MANAGER')).not.toThrow();
  });

  it('orders claim, row lock, inventory update, ledger and completion atomically', async () => {
    const db = new FakeRunner();
    await expect(executeMovementContract(db, command)).resolves.toEqual({
      kind: 'applied',
      balance: 8,
    });
    expect(db.calls).toEqual([
      'claimOrLock',
      'lockInventory',
      'updateOnHand',
      'appendLedger',
      'completeClaim',
    ]);
    expect(db.ledger).toEqual([{ delta: 3, balance: 8 }]);
    db.calls = [];
    await expect(executeMovementContract(db, command)).resolves.toMatchObject({
      kind: 'replay',
      statusCode: 200,
    });
    expect(db.calls).toEqual(['claimOrLock']);
    expect(db.ledger).toHaveLength(1);
    await expect(
      executeMovementContract(db, { ...command, body: { quantity: 99 } }),
    ).resolves.toEqual({ kind: 'conflict' });
  });

  it('rolls back the claim and stock update when ledger insertion fails', async () => {
    const db = new FakeRunner();
    db.failAppend = true;
    await expect(executeMovementContract(db, command)).rejects.toThrow('ledger insert failed');
    expect(db.balance).toBe(5);
    expect(db.record).toBeNull();
    expect(db.ledger).toHaveLength(0);
  });

  it('refuses negative, over-reserved and mismatched inventory before writing', async () => {
    const db = new FakeRunner();
    await expect(executeMovementContract(db, { ...command, delta: -6 })).rejects.toThrow();
    await expect(executeMovementContract(db, { ...command, delta: -4 })).rejects.toThrow(
      'over-reserve',
    );
    db.productId = 'other-product';
    await expect(executeMovementContract(db, command)).rejects.toThrow('mismatch');
    expect(db.balance).toBe(5);
    expect(db.record).toBeNull();
    expect(db.ledger).toHaveLength(0);
  });
});
