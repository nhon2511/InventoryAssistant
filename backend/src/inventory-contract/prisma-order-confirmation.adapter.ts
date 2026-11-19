import { Prisma } from '@prisma/client';
import type { PrismaService } from '../prisma/prisma.service.js';
import { isRetryableTransactionError, PrismaInventoryTransactionPort } from './prisma-inventory-transaction.adapter.js';
import type {
  ConfirmationLine,
  ConfirmationType,
  LockedOrder,
  MatchedInventory,
  OrderConfirmationPort,
  OrderConfirmationRunner,
} from './order-confirmation.service.js';

class PrismaOrderConfirmationPort extends PrismaInventoryTransactionPort implements OrderConfirmationPort {
  async lockOrder(id: string): Promise<LockedOrder> {
    const rows = await this.tx.$queryRaw<LockedOrder[]>`
      SELECT id, type, status, created_by AS "createdBy"
      FROM public.warehouse_orders WHERE id = ${id}::uuid FOR UPDATE
    `;
    if (rows.length !== 1) throw new Error('Order not found');
    return rows[0];
  }

  async loadLines(orderId: string): Promise<ConfirmationLine[]> {
    return this.tx.$queryRaw<ConfirmationLine[]>`
      SELECT id, product_id AS "productId", location_id AS "locationId",
             lot_number AS "lotNumber", expiry_date AS "expiryDate",
             expected_quantity AS "expectedQuantity", actual_quantity AS "actualQuantity"
      FROM public.warehouse_order_items WHERE order_id = ${orderId}::uuid
      ORDER BY id FOR UPDATE
    `;
  }

  async lockInventoryByIdentity(productId: string, locationId: string, lotNumber: string | null): Promise<MatchedInventory[]> {
    return this.tx.$queryRaw<MatchedInventory[]>`
      SELECT id, product_id AS "productId", location_id AS "locationId",
             lot_number AS "lotNumber", expiry_date AS "expiryDate",
             quantity_on_hand AS "quantityOnHand", quantity_reserved AS "quantityReserved"
      FROM public.inventory_items
      WHERE product_id = ${productId}::uuid AND location_id = ${locationId}::uuid
        AND lot_number IS NOT DISTINCT FROM ${lotNumber}
      ORDER BY id FOR UPDATE
    `;
  }

  async completeOrder(id: string, type: ConfirmationType): Promise<void> {
    const result = await this.tx.warehouseOrder.updateMany({
      where: { id, type, status: 'DRAFT' }, data: { status: 'COMPLETED' },
    });
    if (result.count !== 1) throw new Error('Order state changed');
  }
}

// Not registered in AppModule; requires separately approved migration and DB role.
export class PrismaOrderConfirmationAdapter implements OrderConfirmationRunner {
  constructor(
    private readonly prisma: PrismaService,
    private readonly sleep: (ms: number) => Promise<void> = (ms) => new Promise((resolve) => setTimeout(resolve, ms)),
  ) {}

  async transaction<T>(work: (tx: OrderConfirmationPort) => Promise<T>): Promise<T> {
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        return await this.prisma.$transaction(async (tx) => {
          await tx.$queryRaw`SELECT set_config('lock_timeout', '3s', true)`;
          return work(new PrismaOrderConfirmationPort(tx));
        }, { maxWait: 2_000, timeout: 10_000, isolationLevel: Prisma.TransactionIsolationLevel.Serializable });
      } catch (error) {
        if (attempt === 3 || !isRetryableTransactionError(error)) throw error;
        await this.sleep(25 * attempt);
      }
    }
    throw new Error('Unreachable transaction retry state');
  }
}
