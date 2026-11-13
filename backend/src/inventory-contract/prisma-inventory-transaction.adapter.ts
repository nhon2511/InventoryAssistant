import { Prisma } from '@prisma/client';
import type { PrismaService } from '../prisma/prisma.service.js';
import type {
  IdempotencyRecord,
  InventoryTransactionPort,
  InventoryTransactionRunner,
  JsonValue,
  LockedInventoryItem,
} from './inventory-command.contract.js';

const MAX_ATTEMPTS = 3;
const TX_MAX_WAIT_MS = 2_000;
const TX_TIMEOUT_MS = 10_000;

// Prisma v6 uses P2034 for write conflicts/deadlocks. Raw PostgreSQL errors
// may be wrapped in P2010 with a SQLSTATE in meta.code.
export function isRetryableTransactionError(error: unknown): boolean {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError)) return false;
  if (error.code === 'P2034') return true;
  if (error.code !== 'P2010') return false;
  const sqlState = error.meta?.code;
  return sqlState === '40001' || sqlState === '40P01' || sqlState === '55P03';
}

class PrismaInventoryTransactionPort implements InventoryTransactionPort {
  constructor(private readonly tx: Prisma.TransactionClient) {}

  async claimOrLock(input: {
    scopeId: string;
    key: string;
    method: string;
    path: string;
    hash: string;
    now: Date;
    expiresAt: Date;
  }): Promise<IdempotencyRecord | null> {
    const inserted = await this.tx.$queryRaw<Array<{ scope_id: string }>>`
      INSERT INTO public.idempotency_keys
        (scope_id, key, http_method, request_path, request_hash, expires_at)
      VALUES (${input.scopeId}::uuid, ${input.key}, ${input.method},
              ${input.path}, ${input.hash}, ${input.expiresAt})
      ON CONFLICT (scope_id, key) DO NOTHING
      RETURNING scope_id
    `;
    if (inserted.length === 1) return null;
    const rows = await this.tx.$queryRaw<
      Array<{
        httpMethod: string;
        requestPath: string;
        requestHash: string;
        processingStatus: 'processing' | 'completed';
        statusCode: number | null;
        response: Prisma.JsonValue | null;
        expiresAt: Date;
      }>
    >`
      SELECT http_method AS "httpMethod", request_path AS "requestPath",
             request_hash::text AS "requestHash",
             processing_status AS "processingStatus",
             status_code AS "statusCode", response,
             expires_at AS "expiresAt"
      FROM public.idempotency_keys
      WHERE scope_id = ${input.scopeId}::uuid AND key = ${input.key}
      FOR UPDATE
    `;
    if (rows.length !== 1) throw new Error('Idempotency claim disappeared');
    const row = rows[0];
    return { ...row, response: row.response as JsonValue | null };
  }

  async lockInventory(itemId: string): Promise<LockedInventoryItem> {
    const rows = await this.tx.$queryRaw<LockedInventoryItem[]>`
      SELECT id, product_id AS "productId", location_id AS "locationId",
             quantity_on_hand AS "quantityOnHand",
             quantity_reserved AS "quantityReserved"
      FROM public.inventory_items
      WHERE id = ${itemId}::uuid
      FOR UPDATE
    `;
    if (rows.length !== 1) throw new Error('Inventory item not found');
    return rows[0];
  }

  async updateOnHand(itemId: string, balance: number): Promise<void> {
    const result = await this.tx.inventoryItem.updateMany({
      where: { id: itemId },
      data: { quantityOnHand: balance },
    });
    if (result.count !== 1) throw new Error('Inventory update count changed');
  }

  async appendLedger(input: {
    transactionType: 'INBOUND' | 'OUTBOUND';
    inventoryItemId: string;
    productId: string;
    locationId: string;
    delta: number;
    balance: number;
    actorId: string;
    orderId?: string;
  }): Promise<void> {
    await this.tx.stockLedger.create({
      data: {
        transactionType: input.transactionType,
        inventoryItemId: input.inventoryItemId,
        productId: input.productId,
        locationId: input.locationId,
        delta: input.delta,
        balance: input.balance,
        createdBy: input.actorId,
        orderId: input.orderId,
      },
    });
  }

  async completeClaim(input: {
    scopeId: string;
    key: string;
    statusCode: number;
    response: JsonValue;
  }): Promise<void> {
    const result = await this.tx.idempotencyKey.updateMany({
      where: {
        scopeId: input.scopeId,
        key: input.key,
        processingStatus: 'processing',
      },
      data: {
        processingStatus: 'completed',
        statusCode: input.statusCode,
        response: input.response as Prisma.InputJsonValue,
      },
    });
    if (result.count !== 1) throw new Error('Idempotency completion count changed');
  }
}

// Deliberately not registered in AppModule: Cloud tables/role are not deployed.
export class PrismaInventoryTransactionAdapter implements InventoryTransactionRunner {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sleep: (milliseconds: number) => Promise<void> =
      (milliseconds) =>
        new Promise((resolve) => setTimeout(resolve, milliseconds)),
  ) {}

  async transaction<T>(work: (tx: InventoryTransactionPort) => Promise<T>): Promise<T> {
    for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
      try {
        return await this.prisma.$transaction(
          async (tx) => {
            // Session pooler preserves this transaction-local setting.
            await tx.$queryRaw`SELECT set_config('lock_timeout', '3s', true)`;
            return work(new PrismaInventoryTransactionPort(tx));
          },
          {
            maxWait: TX_MAX_WAIT_MS,
            timeout: TX_TIMEOUT_MS,
            isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
          },
        );
      } catch (error) {
        if (attempt === MAX_ATTEMPTS || !isRetryableTransactionError(error)) {
          throw error;
        }
        await this.sleep(25 * attempt);
      }
    }
    throw new Error('Unreachable transaction retry state');
  }
}
