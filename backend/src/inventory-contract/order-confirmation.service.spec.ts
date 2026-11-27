import { describe, expect, it, vi } from 'vitest';
import type { IdempotencyRecord } from './inventory-command.contract.js';
import type { VerifiedPrincipal } from './inventory-command.service.js';
import {
  OrderConfirmationService,
  type ConfirmationLine,
  type ConfirmationType,
  type MatchedInventory,
  type OrderConfirmationPort,
  type OrderConfirmationRunner,
} from './order-confirmation.service.js';

const actor = '00000000-0000-4000-8000-000000000001';
const orderId = '00000000-0000-4000-8000-000000000002';
const product = '00000000-0000-4000-8000-000000000003';
const location = '00000000-0000-4000-8000-000000000004';
const itemId = '00000000-0000-4000-8000-000000000005';
const lineId = '00000000-0000-4000-8000-000000000006';
const now = new Date('2026-11-13T00:00:00Z');
const principal: VerifiedPrincipal = {
  subjectId: actor,
  scopeId: actor,
  issuer: 'https://test.supabase.co/auth/v1',
  audience: 'authenticated',
  authorizationSource: 'verified-jwt',
  trustedRole: 'MANAGER',
};
const input = (
  type: ConfirmationType = 'OUTBOUND',
  key = 'confirmation-1',
  lines = [{ lineId, actualQuantity: 3 }],
) => ({ orderId, type, idempotencyKey: key, lines });

class FakeDb implements OrderConfirmationRunner {
  status = 'CONFIRMED';
  type: ConfirmationType = 'OUTBOUND';
  createdBy: string | null = actor;
  balance = 10;
  reserved = 2;
  lines: ConfirmationLine[] = [
    {
      id: lineId,
      productId: product,
      locationId: location,
      lotNumber: null,
      expiryDate: null,
      expectedQuantity: 3,
      actualQuantity: 0,
    },
  ];
  inventory: MatchedInventory[] = [
    {
      id: itemId,
      productId: product,
      locationId: location,
      lotNumber: null,
      expiryDate: null,
      quantityOnHand: 10,
      quantityReserved: 2,
    },
  ];
  record: IdempotencyRecord | null = null;
  recordKey: string | null = null;
  ledger: Array<{ delta: number; balance: number; orderId?: string }> = [];
  calls: string[] = [];
  failAt?: string;
  private queue: Promise<void> = Promise.resolve();

  async transaction<T>(
    work: (tx: OrderConfirmationPort) => Promise<T>,
  ): Promise<T> {
    const predecessor = this.queue;
    let release!: () => void;
    this.queue = new Promise<void>((resolve) => {
      release = resolve;
    });
    await predecessor;
    try {
      let balance = this.balance;
      let status = this.status;
      let record = this.record;
      let recordKey = this.recordKey;
      let lines = this.lines.map((line) => ({ ...line }));
      const ledger = [...this.ledger];
      const step = (name: string) => {
        this.calls.push(name);
        if (this.failAt === name) throw new Error(`${name} failed`);
      };
      const tx: OrderConfirmationPort = {
        claimOrLock: async (claim) => {
          step('claim');
          if (record && recordKey === claim.key) return record;
          record = {
            httpMethod: claim.method,
            requestPath: claim.path,
            requestHash: claim.hash,
            processingStatus: 'processing',
            statusCode: null,
            response: null,
            expiresAt: claim.expiresAt,
          };
          recordKey = claim.key;
          return null;
        },
        lockOrder: async () => {
          step('order');
          return {
            id: orderId,
            type: this.type,
            status,
            createdBy: this.createdBy,
          };
        },
        loadLines: async () => {
          step('lines');
          return lines;
        },
        updateActualQuantity: async (_order, id, quantity) => {
          step('lineUpdate');
          lines = lines.map((line) =>
            line.id === id ? { ...line, actualQuantity: quantity } : line,
          );
        },
        lockInventoryByIdentity: async (p, l, lot) => {
          step('inventory');
          return this.inventory
            .filter(
              (row) =>
                row.productId === p &&
                row.locationId === l &&
                row.lotNumber === lot,
            )
            .map((row) => ({
              ...row,
              quantityOnHand: balance,
              quantityReserved: this.reserved,
            }));
        },
        lockInventory: async () => {
          throw new Error('unexpected direct lookup');
        },
        updateOnHand: async (_id, next) => {
          step('update');
          balance = next;
        },
        appendLedger: async (entry) => {
          step('ledger');
          ledger.push({
            delta: entry.delta,
            balance: entry.balance,
            orderId: entry.orderId,
          });
        },
        completeOrder: async () => {
          step('completeOrder');
          if (status !== 'CONFIRMED') throw new Error('state changed');
          status = 'COMPLETED';
        },
        completeClaim: async (claim) => {
          step('completeClaim');
          if (!record) throw new Error('missing claim');
          record = {
            ...record,
            processingStatus: 'completed',
            statusCode: claim.statusCode,
            response: claim.response,
          };
        },
      };
      const result = await work(tx);
      this.balance = balance;
      this.status = status;
      this.record = record;
      this.recordKey = recordKey;
      this.lines = lines;
      this.ledger = ledger;
      return result;
    } finally {
      release();
    }
  }
}

function fixture(role: VerifiedPrincipal['trustedRole'] = 'MANAGER') {
  const db = new FakeDb();
  const verifyAccessToken = vi.fn(async (): Promise<VerifiedPrincipal> => ({
    ...principal,
    trustedRole: role,
  }));
  const service = new OrderConfirmationService(
    db,
    { verifyAccessToken },
    () => now,
  );
  return { db, service, verifyAccessToken };
}

describe('offline order confirmation transaction', () => {
  it('confirms inbound with one stock update, ledger append and state transition', async () => {
    const { db, service } = fixture();
    db.type = 'INBOUND';
    await expect(service.confirm('token', input('INBOUND'))).resolves.toEqual({
      kind: 'applied',
      orderId,
      movements: 1,
    });
    expect(db.balance).toBe(13);
    expect(db.status).toBe('COMPLETED');
    expect(db.ledger).toEqual([{ delta: 3, balance: 13, orderId }]);
    expect(db.lines[0].actualQuantity).toBe(3);
    expect(db.calls).toEqual([
      'claim',
      'order',
      'lines',
      'inventory',
      'lineUpdate',
      'update',
      'ledger',
      'completeOrder',
      'completeClaim',
    ]);
  });

  it('confirms outbound using available stock without clamping to zero', async () => {
    const { db, service } = fixture();
    await expect(service.confirm('token', input())).resolves.toMatchObject({
      kind: 'applied',
    });
    expect(db.balance).toBe(7);
    expect(db.ledger).toEqual([{ delta: -3, balance: 7, orderId }]);
  });

  it('replays one key, rejects changed body/key and prevents a second business event', async () => {
    const { db, service } = fixture();
    await service.confirm('token', input());
    db.calls = [];
    await expect(service.confirm('token', input())).resolves.toEqual({
      kind: 'replay',
      orderId,
      movements: 1,
    });
    expect(db.calls).toEqual(['claim']);
    await expect(service.confirm('token', input('INBOUND'))).resolves.toEqual({
      kind: 'conflict',
    });
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [{ lineId, actualQuantity: 2 }]),
      ),
    ).resolves.toEqual({ kind: 'conflict' });
    await expect(
      service.confirm('token', input('OUTBOUND', 'other-key')),
    ).rejects.toThrow('Order cannot be confirmed');
    expect(db.ledger).toHaveLength(1);
  });

  it('rejects wrong type/status, missing owner and unauthorized principal before side effects', async () => {
    const { db, service, verifyAccessToken } = fixture();
    db.type = 'INBOUND';
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Order cannot be confirmed',
    );
    db.type = 'OUTBOUND';
    db.status = 'COMPLETED';
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Order cannot be confirmed',
    );
    db.status = 'DRAFT';
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Order cannot be confirmed',
    );
    db.status = 'CANCELLED';
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Order cannot be confirmed',
    );
    db.status = 'CONFIRMED';
    db.createdBy = null;
    await expect(service.confirm('token', input())).rejects.toThrow(
      'ownership',
    );
    expect(db.ledger).toHaveLength(0);
    verifyAccessToken.mockRejectedValueOnce(new Error('invalid JWT'));
    await expect(service.confirm('invalid', input())).rejects.toThrow(
      'invalid JWT',
    );
    expect(db.calls.filter((call) => call === 'claim')).toHaveLength(5);
    const staff = fixture('STAFF');
    await expect(staff.service.confirm('token', input())).rejects.toThrow(
      'Trusted confirmation authority',
    );
    expect(staff.db.calls).toHaveLength(0);
    const denied = fixture();
    denied.verifyAccessToken.mockResolvedValueOnce({
      ...principal,
      trustedRole: undefined,
    });
    await expect(denied.service.confirm('token', input())).rejects.toThrow(
      'Trusted confirmation authority',
    );
    expect(denied.db.calls).toHaveLength(0);
  });

  it('rejects null location, duplicate nullable-lot rows, mismatched expiry and no existing item', async () => {
    const { db, service } = fixture();
    db.lines[0].locationId = null;
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Invalid order line',
    );
    db.lines[0].locationId = location;
    db.inventory.push({
      ...db.inventory[0],
      id: '00000000-0000-4000-8000-000000000007',
    });
    await expect(service.confirm('token', input())).rejects.toThrow(
      'ambiguous',
    );
    db.inventory.pop();
    db.inventory[0].expiryDate = new Date('2026-12-01');
    await expect(service.confirm('token', input())).rejects.toThrow(
      'identity mismatch',
    );
    db.inventory = [];
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Missing or ambiguous',
    );
    expect(db.ledger).toHaveLength(0);
  });

  it('rejects insufficient stock and rolls back all lines on a later ledger failure', async () => {
    const { db, service } = fixture();
    db.balance = 4;
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Insufficient available stock',
    );
    db.balance = 10;
    const secondId = '00000000-0000-4000-8000-000000000008';
    db.lines.push({
      ...db.lines[0],
      id: secondId,
      actualQuantity: 0,
      expectedQuantity: 2,
    });
    db.failAt = 'completeOrder';
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [
          { lineId, actualQuantity: 3 },
          { lineId: secondId, actualQuantity: 2 },
        ]),
      ),
    ).rejects.toThrow('completeOrder failed');
    expect(db.balance).toBe(10);
    expect(db.lines.every((line) => line.actualQuantity === 0)).toBe(true);
    expect(db.status).toBe('CONFIRMED');
    expect(db.ledger).toHaveLength(0);
    expect(db.record).toBeNull();
  });

  it('rejects empty orders, zero actual quantity and inventory identity drift', async () => {
    const { db, service } = fixture();
    const original = db.lines[0];
    db.lines = [];
    await expect(service.confirm('token', input())).rejects.toThrow('no lines');
    db.lines = [original];
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [{ lineId, actualQuantity: 0 }]),
      ),
    ).rejects.toThrow('Invalid confirmation request');
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [{ lineId, actualQuantity: -1 }]),
      ),
    ).rejects.toThrow('Invalid confirmation request');
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [{ lineId, actualQuantity: 4 }]),
      ),
    ).rejects.toThrow('exceeds expected');
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [
          { lineId: itemId, actualQuantity: 1 },
        ]),
      ),
    ).rejects.toThrow('must match every order line');
    await expect(
      service.confirm(
        'token',
        input('OUTBOUND', 'confirmation-1', [
          { lineId, actualQuantity: 1 },
          { lineId, actualQuantity: 1 },
        ]),
      ),
    ).rejects.toThrow('Invalid confirmation request');
    db.lines = [original];
    db.inventory[0].productId = '00000000-0000-4000-8000-000000000009';
    await expect(service.confirm('token', input())).rejects.toThrow(
      'Missing or ambiguous',
    );
    expect(db.balance).toBe(10);
    expect(db.record).toBeNull();
  });

  it('keeps deterministic ledger balances for two lines and rolls back a late ledger error', async () => {
    const { db, service } = fixture();
    const secondId = '00000000-0000-4000-8000-000000000008';
    db.lines.push({
      ...db.lines[0],
      id: secondId,
      expectedQuantity: 2,
      actualQuantity: 0,
    });
    const twoLines = input('OUTBOUND', 'confirmation-1', [
      { lineId, actualQuantity: 3 },
      { lineId: secondId, actualQuantity: 2 },
    ]);
    await expect(service.confirm('token', twoLines)).resolves.toMatchObject({
      movements: 2,
    });
    expect(db.ledger).toEqual([
      { delta: -3, balance: 7, orderId },
      { delta: -2, balance: 5, orderId },
    ]);
    const failing = fixture();
    failing.db.lines = [...db.lines];
    failing.db.failAt = 'ledger';
    await expect(failing.service.confirm('token', twoLines)).rejects.toThrow(
      'ledger failed',
    );
    expect(failing.db.balance).toBe(10);
    expect(failing.db.status).toBe('CONFIRMED');
    expect(failing.db.ledger).toHaveLength(0);
  });

  it('simulates concurrent duplicate claim serialization, without asserting PostgreSQL behavior', async () => {
    const f = fixture();
    const results = await Promise.all([
      f.service.confirm('token', input()),
      f.service.confirm('token', input()),
    ]);
    expect(results.map((x) => x.kind).sort()).toEqual(['applied', 'replay']);
    expect(f.db.ledger).toHaveLength(1);
  });
});
