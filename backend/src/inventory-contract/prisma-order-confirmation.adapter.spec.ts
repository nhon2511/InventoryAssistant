import { Prisma } from '@prisma/client';
import { describe, expect, it, vi } from 'vitest';
import type { PrismaService } from '../prisma/prisma.service.js';
import { PrismaOrderConfirmationAdapter } from './prisma-order-confirmation.adapter.js';

const actor = '00000000-0000-4000-8000-000000000001';
const orderId = '00000000-0000-4000-8000-000000000002';
const product = '00000000-0000-4000-8000-000000000003';
const location = '00000000-0000-4000-8000-000000000004';
const itemId = '00000000-0000-4000-8000-000000000005';

function fixture() {
  const sql: string[] = [];
  const raw = vi.fn(async (parts: TemplateStringsArray) => {
    const statement = parts.join('?');
    sql.push(statement);
    if (statement.includes('set_config')) return [{}];
    if (statement.includes('INSERT INTO public.idempotency_keys')) return [{ scope_id: actor }];
    if (statement.includes('FROM public.warehouse_orders')) return [{ id: orderId, type: 'OUTBOUND', status: 'DRAFT', createdBy: actor }];
    if (statement.includes('FROM public.warehouse_order_items')) return [{
      id: '00000000-0000-4000-8000-000000000006', productId: product, locationId: location,
      lotNumber: null, expiryDate: null, expectedQuantity: 2, actualQuantity: 2,
    }];
    if (statement.includes('FROM public.inventory_items')) return [{ id: itemId, productId: product,
      locationId: location, lotNumber: null, expiryDate: null, quantityOnHand: 5, quantityReserved: 1 }];
    throw new Error('Unexpected SQL');
  });
  const updateStock = vi.fn(async () => ({ count: 1 }));
  const ledger = vi.fn(async () => ({ id: 'ledger' }));
  const updateOrder = vi.fn(async () => ({ count: 1 }));
  const completeKey = vi.fn(async () => ({ count: 1 }));
  const tx = { $queryRaw: raw, inventoryItem: { updateMany: updateStock },
    stockLedger: { create: ledger }, warehouseOrder: { updateMany: updateOrder },
    idempotencyKey: { updateMany: completeKey } };
  const run = vi.fn(async (work: (client: typeof tx) => Promise<unknown>, _options?: unknown) => work(tx));
  const adapter = new PrismaOrderConfirmationAdapter({ $transaction: run } as unknown as PrismaService, async () => {});
  return { adapter, run, raw, sql, updateStock, ledger, updateOrder, completeKey };
}

describe('unwired Prisma confirmation adapter (SQL-shaped mocks)', () => {
  it('uses one serializable transaction, parameterized locks and count-checked updates', async () => {
    const f = fixture();
    await f.adapter.transaction(async (tx) => {
      await tx.claimOrLock({ scopeId: actor, key: 'key', method: 'POST', path: '/orders/x', hash: 'a'.repeat(64),
        now: new Date(), expiresAt: new Date(Date.now() + 60_000) });
      expect(await tx.lockOrder(orderId)).toMatchObject({ status: 'DRAFT' });
      expect(await tx.loadLines(orderId)).toHaveLength(1);
      expect(await tx.lockInventoryByIdentity(product, location, null)).toHaveLength(1);
      await tx.updateOnHand(itemId, 3);
      await tx.appendLedger({ transactionType: 'OUTBOUND', inventoryItemId: itemId, productId: product,
        locationId: location, delta: -2, balance: 3, actorId: actor, orderId });
      await tx.completeOrder(orderId, 'OUTBOUND');
      await tx.completeClaim({ scopeId: actor, key: 'key', statusCode: 200,
        response: { orderId, movements: 1 } });
    });
    expect(f.run).toHaveBeenCalledTimes(1);
    expect(f.run.mock.calls[0][1]).toMatchObject({ isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
      maxWait: 2000, timeout: 10000 });
    expect(f.sql.some((s) => s.includes('FROM public.warehouse_orders') && s.includes('FOR UPDATE'))).toBe(true);
    expect(f.sql.some((s) => s.includes('FROM public.warehouse_order_items') && s.includes('ORDER BY id FOR UPDATE'))).toBe(true);
    expect(f.sql.some((s) => s.includes('IS NOT DISTINCT FROM') && s.includes('ORDER BY id FOR UPDATE'))).toBe(true);
    expect(f.sql.join(' ')).not.toContain(orderId);
    expect(f.updateStock).toHaveBeenCalledWith({ where: { id: itemId }, data: { quantityOnHand: 3 } });
    expect(f.updateOrder).toHaveBeenCalledWith({ where: { id: orderId, type: 'OUTBOUND', status: 'DRAFT' },
      data: { status: 'COMPLETED' } });
    expect(f.ledger).toHaveBeenCalledTimes(1);
    expect(f.completeKey).toHaveBeenCalledTimes(1);
  });

  it('propagates state count failure before claim completion', async () => {
    const f = fixture();
    f.updateOrder.mockResolvedValueOnce({ count: 0 });
    await expect(f.adapter.transaction((tx) => tx.completeOrder(orderId, 'INBOUND')))
      .rejects.toThrow('Order state changed');
    expect(f.completeKey).not.toHaveBeenCalled();
  });
});
