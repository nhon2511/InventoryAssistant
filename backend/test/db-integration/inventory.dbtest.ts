import { Prisma } from '@prisma/client';
import { randomUUID } from 'node:crypto';
import { afterAll, beforeAll, describe, expect, it } from 'vitest';
import type { PrismaService } from '../../src/prisma/prisma.service.js';
import { OrdersService } from '../../src/orders/orders.service.js';
import { OrderTypeEnum } from '../../src/orders/dto/order-query.dto.js';
import { OrderConfirmationService } from '../../src/inventory-contract/order-confirmation.service.js';
import { PrismaOrderConfirmationAdapter } from '../../src/inventory-contract/prisma-order-confirmation.adapter.js';
import { admin, assertLiveTestTarget, backend, fixture, testActorId, withRollback } from './harness.js';

beforeAll(assertLiveTestTarget);
afterAll(async () => { await Promise.all([admin.$disconnect(), backend.$disconnect()]); });

function serviceOn(
  tx: Prisma.TransactionClient,
  trustedRole: 'ADMIN' | 'MANAGER' | 'STAFF' = 'MANAGER',
) {
  // Real SQL on an outer rollback-only transaction. This does not exercise a
  // separate committed adapter transaction or backend role connection.
  const proxy = { $transaction: async (work: (client: Prisma.TransactionClient) => Promise<unknown>) => work(tx) };
  const adapter = new PrismaOrderConfirmationAdapter(proxy as unknown as PrismaService, async () => {});
  return new OrderConfirmationService(adapter, {
    verifyAccessToken: async () => ({
      subjectId: testActorId, scopeId: testActorId,
      issuer: 'https://isolated-test.supabase.co/auth/v1', audience: 'authenticated',
      authorizationSource: 'verified-jwt', trustedRole,
    }),
  });
}

function ordersServiceOn(tx: Prisma.TransactionClient) {
  // Keep create/review inside the outer rollback-only fixture transaction.
  const prisma = new Proxy(tx, {
    get(target, property) {
      if (property === '$transaction') {
        return async (work: (client: Prisma.TransactionClient) => Promise<unknown>) => work(tx);
      }
      return Reflect.get(target, property, target);
    },
  });
  return new OrdersService(prisma as unknown as PrismaService);
}

function confirmationInput(
  f: Awaited<ReturnType<typeof fixture>>,
  type: 'INBOUND' | 'OUTBOUND' = 'OUTBOUND',
  idempotencyKey = `CP5-${f.order.id}`,
  actualQuantity = 3,
) {
  return {
    orderId: f.order.id,
    type,
    idempotencyKey,
    lines: [{ lineId: f.line.id, actualQuantity }],
  };
}

describe('real PostgreSQL in rollback-only isolated test target', () => {
  it('creates a multi-line draft, reviews it, records actuals, and replays once', async () => {
    await withRollback(async (tx) => {
      const first = await fixture(tx);
      const secondProduct = await tx.product.create({ data: {
        sku: `CP5-${randomUUID().slice(0, 8)}`,
        barcode: `CP5-BC-${randomUUID().slice(0, 8)}`,
        name: 'CP5 demo second product',
      } });
      const secondLocation = await tx.location.create({ data: {
        zoneCode: 'CP5', aisleCode: 'A002', rackCode: 'R1', binCode: 'B2',
        locationBarcode: `CP5-LOC-${randomUUID().slice(0, 8)}`,
      } });
      const secondInventory = await tx.inventoryItem.create({ data: {
        productId: secondProduct.id, locationId: secondLocation.id,
        quantityOnHand: 8, quantityReserved: 1, lotNumber: 'CP5-DEMO-LOT-2',
      } });
      const orders = ordersServiceOn(tx);
      const draft = await orders.createDraft({
        type: OrderTypeEnum.OUTBOUND,
        requestId: randomUUID(),
        items: [
          { productId: first.product.id, locationId: first.location.id, expectedQuantity: 4, lotNumber: first.inventory.lotNumber! },
          { productId: secondProduct.id, locationId: secondLocation.id, expectedQuantity: 3, lotNumber: secondInventory.lotNumber! },
        ],
      }, testActorId);
      expect(draft.status).toBe('DRAFT');
      expect(draft.items).toHaveLength(2);

      const reviewed = await orders.reviewOrder(draft.id, true, testActorId);
      expect(reviewed).toMatchObject({ status: 'CONFIRMED', approvedBy: testActorId });
      const lines = reviewed.items.map((line, index) => ({
        lineId: line.id,
        actualQuantity: index === 0 ? 2 : 3,
      }));
      const service = serviceOn(tx);
      const command = {
        orderId: draft.id,
        type: 'OUTBOUND' as const,
        idempotencyKey: `CP5-${draft.id}`,
        lines,
      };

      expect(await service.confirm('test-token', command)).toMatchObject({ kind: 'applied', movements: 2 });
      expect(await service.confirm('test-token', command)).toMatchObject({ kind: 'replay', movements: 2 });
      expect(await tx.stockLedger.count({ where: { orderId: draft.id } })).toBe(2);
      expect((await tx.inventoryItem.findUniqueOrThrow({ where: { id: first.inventory.id } })).quantityOnHand).toBe(8);
      expect((await tx.inventoryItem.findUniqueOrThrow({ where: { id: secondInventory.id } })).quantityOnHand).toBe(5);
    });
  });

  it('requires candidate schema, FK/CHECK, append-only trigger and RLS catalog objects', async () => {
    await withRollback(async (tx) => {
      const rows = await tx.$queryRaw<Array<{ name: string; rls: boolean }>>`
        SELECT relname AS name, relrowsecurity AS rls FROM pg_class
        WHERE oid IN ('public.stock_ledger'::regclass, 'public.idempotency_keys'::regclass)
      `;
      expect(rows).toHaveLength(2);
      expect(rows.every((row) => row.rls)).toBe(true);
      const triggers = await tx.$queryRaw<Array<{ count: bigint }>>`
        SELECT count(*) AS count FROM pg_trigger
        WHERE tgrelid = 'public.stock_ledger'::regclass AND NOT tgisinternal
      `;
      expect(Number(triggers[0].count)).toBeGreaterThanOrEqual(2);
      const constraints = await tx.$queryRaw<Array<{ name: string }>>`
        SELECT conname AS name FROM pg_constraint
        WHERE conrelid IN ('public.stock_ledger'::regclass, 'public.idempotency_keys'::regclass)
      `;
      expect(constraints.some((constraint) => constraint.name.includes('pkey'))).toBe(true);
      expect(constraints.some((constraint) => constraint.name.includes('fkey'))).toBe(true);
      expect(constraints.some((constraint) => constraint.name.includes('check'))).toBe(true);
    });
  });

  it('confirms one order with real row locks, ledger balance and idempotent replay', async () => {
    await withRollback(async (tx) => {
      const f = await fixture(tx);
      const service = serviceOn(tx);
      const command = confirmationInput(f);
      expect((await service.confirm('test-token', command)).kind).toBe('applied');
      const item = await tx.inventoryItem.findUniqueOrThrow({ where: { id: f.inventory.id } });
      expect(item.quantityOnHand).toBe(7);
      const ledger = await tx.stockLedger.findMany({ where: { orderId: f.order.id } });
      expect(ledger).toHaveLength(1);
      expect(ledger[0]).toMatchObject({ inventoryItemId: f.inventory.id, delta: -3, balance: 7 });
      expect((await service.confirm('test-token', command)).kind).toBe('replay');
      expect(await tx.stockLedger.count({ where: { orderId: f.order.id } })).toBe(1);
      await expect(service.confirm('test-token', {
        ...command,
        lines: [{ lineId: f.line.id, actualQuantity: 2 }],
      })).resolves.toMatchObject({ kind: 'conflict' });
      await expect(service.confirm('test-token', { ...command, idempotencyKey: `CP5-other-${f.order.id}` }))
        .rejects.toThrow('Order cannot be confirmed');
      await expect(service.confirm('test-token', { ...command, type: 'INBOUND' }))
        .resolves.toMatchObject({ kind: 'conflict' });
    });
  });

  it('confirms inbound against an existing exact inventory identity', async () => {
    await withRollback(async (tx) => {
      const f = await fixture(tx, 'INBOUND');
      const result = await serviceOn(tx).confirm('test-token', confirmationInput(f, 'INBOUND'));
      expect(result.kind).toBe('applied');
      expect((await tx.inventoryItem.findUniqueOrThrow({ where: { id: f.inventory.id } })).quantityOnHand).toBe(13);
      expect(await tx.stockLedger.findMany({ where: { orderId: f.order.id }, select: { delta: true, balance: true } }))
        .toEqual([{ delta: 3, balance: 13 }]);
    });
  });

  it('rejects insufficient available stock before stock/ledger writes', async () => {
    await withRollback(async (tx) => {
      const f = await fixture(tx);
      await tx.warehouseOrderItem.update({ where: { id: f.line.id }, data: { expectedQuantity: 12 } });
      const service = serviceOn(tx);
      await expect(service.confirm('test-token', confirmationInput(f, 'OUTBOUND', undefined, 9)))
        .rejects.toThrow('Insufficient available stock');
      expect((await tx.inventoryItem.findUniqueOrThrow({ where: { id: f.inventory.id } })).quantityOnHand).toBe(10);
      expect(await tx.stockLedger.count({ where: { orderId: f.order.id } })).toBe(0);
    });
  });

  it('rejects confirmation for DRAFT and CANCELLED orders', async () => {
    await withRollback(async (tx) => {
      const f = await fixture(tx);
      const service = serviceOn(tx);
      await tx.warehouseOrder.update({ where: { id: f.order.id }, data: { status: 'DRAFT' } });
      await expect(service.confirm('test-token', confirmationInput(f)))
        .rejects.toThrow('Order cannot be confirmed');
      await tx.warehouseOrder.update({ where: { id: f.order.id }, data: { status: 'CANCELLED' } });
      await expect(service.confirm('test-token', confirmationInput(f, 'OUTBOUND', `CP5-cancelled-${f.order.id}`)))
        .rejects.toThrow('Order cannot be confirmed');
      expect(await tx.stockLedger.count({ where: { orderId: f.order.id } })).toBe(0);
    });
  });

  it('rejects a CHECK-violating ledger row and rolls back the fixture', async () => {
    await expect(withRollback(async (tx) => {
      const f = await fixture(tx);
      await tx.stockLedger.create({ data: {
        inventoryItemId: f.inventory.id, productId: f.product.id, locationId: f.location.id,
        orderId: f.order.id, createdBy: testActorId, transactionType: 'OUTBOUND', delta: 0, balance: 10,
      } });
    })).rejects.toThrow();
  });

  it('rejects an order line with a missing product FK', async () => {
    await expect(withRollback(async (tx) => {
      const f = await fixture(tx);
      await tx.warehouseOrderItem.create({ data: {
        orderId: f.order.id, productId: '00000000-0000-4000-8000-000000000099',
        locationId: f.location.id, expectedQuantity: 1, actualQuantity: 1,
      } });
    })).rejects.toThrow();
  });

  it('fails closed on duplicate NULL-lot inventory rows', async () => {
    await withRollback(async (tx) => {
      const f = await fixture(tx, 'INBOUND');
      await tx.inventoryItem.update({ where: { id: f.inventory.id }, data: { lotNumber: null } });
      await tx.warehouseOrderItem.update({ where: { id: f.line.id }, data: { lotNumber: null } });
      await tx.inventoryItem.create({ data: {
        productId: f.product.id, locationId: f.location.id, lotNumber: null,
        quantityOnHand: 0, quantityReserved: 0,
      } });
      await expect(serviceOn(tx).confirm('test-token', confirmationInput(f, 'INBOUND')))
        .rejects.toThrow('Missing or ambiguous inventory identity');
    });
  });

  it('rejects ledger UPDATE through append-only trigger', async () => {
    await expect(withRollback(async (tx) => {
      const f = await fixture(tx);
      const ledger = await tx.stockLedger.create({ data: {
        inventoryItemId: f.inventory.id, productId: f.product.id, locationId: f.location.id,
        orderId: f.order.id, createdBy: testActorId, transactionType: 'INBOUND', delta: 1, balance: 11,
      } });
      await tx.stockLedger.update({ where: { id: ledger.id }, data: { balance: 12 } });
    })).rejects.toThrow();
  });

  it('rejects an untrusted STAFF role before stock or ledger writes', async () => {
    await withRollback(async (tx) => {
      const f = await fixture(tx);
      await expect(serviceOn(tx, 'STAFF').confirm('test-token', confirmationInput(f)))
        .rejects.toThrow('Trusted confirmation authority is unavailable');
      expect(await tx.stockLedger.count({ where: { orderId: f.order.id } })).toBe(0);
    });
  });

  it('checks client ACL and actual backend role without changing database grants', async () => {
    await withRollback(async (tx) => {
      const rows = await tx.$queryRaw<Array<{ anon_insert: boolean; authenticated_insert: boolean }>>`
        SELECT has_table_privilege('anon', 'public.stock_ledger', 'INSERT') AS anon_insert,
               has_table_privilege('authenticated', 'public.idempotency_keys', 'INSERT') AS authenticated_insert
      `;
      expect(rows[0]).toEqual({ anon_insert: false, authenticated_insert: false });
    });
    const identity = await backend.$queryRaw<Array<{ role_name: string }>>`SELECT current_user AS role_name`;
    expect(identity[0].role_name).toBe('wms_backend');
    const privileges = await admin.$queryRaw<Array<{ can_lock: boolean; has_policy: boolean }>>`
      SELECT has_column_privilege('wms_backend', 'public.warehouse_order_items', 'actual_quantity', 'UPDATE') AS can_lock,
             EXISTS (SELECT 1 FROM pg_policies WHERE schemaname = 'public'
               AND tablename = 'warehouse_order_items' AND policyname = 'wms_backend_lock_order_items') AS has_policy
    `;
    expect(privileges[0]).toEqual({ can_lock: true, has_policy: true });
    // No fixture required: parse/permission/RLS check on the actual login role.
    await backend.$transaction(async (tx) => {
      const rows = await tx.$queryRaw<Array<{ id: string }>>`
        SELECT id FROM public.warehouse_order_items WHERE false FOR UPDATE
      `;
      expect(rows).toEqual([]);
    }, { timeout: 10_000 });
  });

  it('rejects a direct authenticated-role idempotency insert', async () => {
    await expect(withRollback(async (tx) => {
      await tx.$executeRaw`SET LOCAL ROLE authenticated`;
      await tx.$executeRaw`
        INSERT INTO public.idempotency_keys
          (scope_id, key, http_method, request_path, request_hash, expires_at)
        VALUES (${testActorId}::uuid, 'B7-client-denial', 'POST', '/b7/denied',
                ${'a'.repeat(64)}, now() + interval '1 hour')
      `;
    })).rejects.toThrow();
  });

  it.todo('two sessions with one idempotency key: one commit, one replay, one ledger row');
  it.todo('two keys confirm the same order concurrently: one commit, one state conflict');
  it.todo('two orders lock the same inventory identity in fixed order under load');
  it.todo('serialization retry, lock timeout and rollback after a later line failure');
  it.todo('client PostgREST role cannot write ledger/keys, including default grants');
});
