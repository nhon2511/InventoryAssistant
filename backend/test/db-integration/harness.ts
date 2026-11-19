import { randomUUID } from 'node:crypto';
import { Prisma, PrismaClient } from '@prisma/client';
import { assertDbTestTarget } from './target.js';

const target = assertDbTestTarget(process.env);
export const admin = new PrismaClient({ datasources: { db: { url: target.url } }, log: [] });
export const backend = new PrismaClient({ datasources: { db: { url: target.backendUrl } }, log: [] });
export const testActorId = target.actorId;

export async function assertLiveTestTarget(): Promise<void> {
  // First database operation is read-only and bounded. No target details are logged.
  const rows = await admin.$transaction(async (tx) => {
    await tx.$executeRaw`SET TRANSACTION READ ONLY`;
    await tx.$executeRaw`SET LOCAL statement_timeout = '5s'`;
    return tx.$queryRaw<Array<{
      database_name: string; role_name: string; version_num: string;
      actor_exists: boolean; ledger_exists: boolean; keys_exists: boolean;
    }>>`
      SELECT current_database() AS database_name, current_user AS role_name,
             current_setting('server_version_num') AS version_num,
             EXISTS (SELECT 1 FROM auth.users WHERE id = ${testActorId}::uuid) AS actor_exists,
             to_regclass('public.stock_ledger') IS NOT NULL AS ledger_exists,
             to_regclass('public.idempotency_keys') IS NOT NULL AS keys_exists
    `;
  }, { timeout: 10_000 });
  const row = rows[0];
  if (!row || row.database_name !== 'postgres' || row.role_name !== 'postgres' ||
      Math.floor(Number(row.version_num) / 10000) !== 17 ||
      !row.actor_exists || !row.ledger_exists || !row.keys_exists) {
    throw new Error('DB integration preflight failed: target, PG17, test actor or schema missing');
  }
  const backendRole = await backend.$transaction(async (tx) => {
    await tx.$executeRaw`SET TRANSACTION READ ONLY`;
    return tx.$queryRaw<Array<{ role_name: string; database_name: string }>>`
      SELECT current_user AS role_name, current_database() AS database_name
    `;
  }, { timeout: 10_000 });
  if (backendRole[0]?.role_name !== 'wms_backend' || backendRole[0]?.database_name !== 'postgres') {
    throw new Error('DB integration backend role preflight failed');
  }
}

const ROLLBACK = Symbol('rollback test fixture');
export async function withRollback<T>(work: (tx: Prisma.TransactionClient) => Promise<T>): Promise<T> {
  let value: T | undefined;
  try {
    await admin.$transaction(async (tx) => {
      await tx.$executeRaw`SET LOCAL lock_timeout = '3s'`;
      await tx.$executeRaw`SET LOCAL statement_timeout = '20s'`;
      value = await work(tx);
      throw ROLLBACK;
    }, { timeout: 25_000, isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
  } catch (error) {
    if (error !== ROLLBACK) throw error;
  }
  return value as T;
}

export async function fixture(tx: Prisma.TransactionClient, type: 'INBOUND' | 'OUTBOUND' = 'OUTBOUND') {
  const suffix = randomUUID().replaceAll('-', '').slice(0, 12);
  const product = await tx.product.create({ data: {
    sku: `B7-${suffix}`, barcode: `B7-BC-${suffix}`, name: `B7 test ${suffix}`,
  } });
  const location = await tx.location.create({ data: {
    zoneCode: 'B7', aisleCode: suffix.slice(0, 4), rackCode: 'R', binCode: 'B',
    locationBarcode: `B7-LOC-${suffix}`,
  } });
  const inventory = await tx.inventoryItem.create({ data: {
    productId: product.id, locationId: location.id, quantityOnHand: 10,
    quantityReserved: 2, lotNumber: `B7-${suffix}`,
  } });
  const order = await tx.warehouseOrder.create({ data: {
    orderCode: `B7-${suffix}`, type, status: 'DRAFT', createdBy: testActorId,
  } });
  const line = await tx.warehouseOrderItem.create({ data: {
    orderId: order.id, productId: product.id, locationId: location.id,
    expectedQuantity: 3, actualQuantity: 3, lotNumber: inventory.lotNumber,
  } });
  return { product, location, inventory, order, line };
}
