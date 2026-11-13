import {
  decideClaim,
  nextOnHand,
  requestFingerprint,
  type InventoryTransactionPort,
} from './inventory-command.contract.js';
import type { VerifiedPrincipal, VerifiedPrincipalProvider } from './inventory-command.service.js';

export type ConfirmationType = 'INBOUND' | 'OUTBOUND';
export interface LockedOrder {
  id: string;
  type: string;
  status: string;
  createdBy: string | null;
}
export interface ConfirmationLine {
  id: string;
  productId: string;
  locationId: string | null;
  lotNumber: string | null;
  expiryDate: Date | null;
  expectedQuantity: number;
  actualQuantity: number;
}
export interface MatchedInventory {
  id: string;
  productId: string;
  locationId: string;
  lotNumber: string | null;
  expiryDate: Date | null;
  quantityOnHand: number;
  quantityReserved: number;
}
export interface OrderConfirmationPort extends InventoryTransactionPort {
  lockOrder(id: string): Promise<LockedOrder>;
  loadLines(orderId: string): Promise<ConfirmationLine[]>;
  lockInventoryByIdentity(productId: string, locationId: string, lotNumber: string | null): Promise<MatchedInventory[]>;
  completeOrder(id: string, type: ConfirmationType): Promise<void>;
}
export interface OrderConfirmationRunner {
  transaction<T>(work: (tx: OrderConfirmationPort) => Promise<T>): Promise<T>;
}
export type ConfirmationResult =
  | { kind: 'applied'; orderId: string; movements: number }
  | { kind: 'replay'; orderId: string; movements: number }
  | { kind: 'conflict' | 'in_progress' | 'expired' };

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
function dateKey(value: Date | null): string | null {
  return value?.toISOString().slice(0, 10) ?? null;
}
function checkedPrincipal(principal: VerifiedPrincipal): void {
  if (!UUID.test(principal.subjectId) || principal.scopeId !== principal.subjectId ||
      !principal.issuer || principal.audience !== 'authenticated' ||
      !['verified-jwt', 'supabase-auth'].includes(principal.authorizationSource) ||
      !principal.trustedRole || !['ADMIN', 'MANAGER', 'STAFF'].includes(principal.trustedRole)) {
    throw new Error('Trusted confirmation authority is unavailable');
  }
}

// Offline only: no module or controller registers this service or its adapter.
export class OrderConfirmationService {
  constructor(
    private readonly runner: OrderConfirmationRunner,
    private readonly principals: VerifiedPrincipalProvider,
    private readonly now: () => Date = () => new Date(),
  ) {}

  async confirm(token: string, input: { orderId: string; type: ConfirmationType; idempotencyKey: string }): Promise<ConfirmationResult> {
    const principal = await this.principals.verifyAccessToken(token);
    checkedPrincipal(principal);
    if (!UUID.test(input.orderId) || !['INBOUND', 'OUTBOUND'].includes(input.type) ||
        input.idempotencyKey.length < 1 || input.idempotencyKey.length > 200) {
      throw new Error('Invalid confirmation request');
    }
    const now = this.now();
    const path = `/backend/orders/${input.orderId}/confirm-${input.type.toLowerCase()}`;
    const hash = requestFingerprint('POST', path, { orderId: input.orderId, type: input.type });
    return this.runner.transaction(async (tx) => {
      const existing = await tx.claimOrLock({
        scopeId: principal.scopeId, key: input.idempotencyKey,
        method: 'POST', path, hash, now,
        expiresAt: new Date(now.getTime() + 24 * 60 * 60 * 1000),
      });
      const claim = decideClaim(existing, { method: 'POST', path, hash }, now);
      if (claim.kind === 'conflict' || claim.kind === 'in_progress' || claim.kind === 'expired') return claim;
      if (claim.kind === 'replay') {
        const response = claim.response;
        if (!response || typeof response !== 'object' || Array.isArray(response) ||
            response.orderId !== input.orderId || !Number.isSafeInteger(response.movements)) {
          throw new Error('Corrupt confirmation replay');
        }
        return { kind: 'replay', orderId: input.orderId, movements: response.movements as number };
      }

      const order = await tx.lockOrder(input.orderId);
      // Even privileged roles cannot bypass ownership until a separate policy is approved.
      if (order.id !== input.orderId || order.createdBy !== principal.subjectId) throw new Error('Order ownership mismatch');
      if (order.type !== input.type || order.status !== 'DRAFT') throw new Error('Order cannot be confirmed');
      const lines = await tx.loadLines(order.id);
      if (lines.length === 0) throw new Error('Order has no lines');
      const sorted = [...lines].sort((a, b) => {
        const left = `${a.productId}|${a.locationId ?? ''}|${a.lotNumber ?? ''}|${a.id}`;
        const right = `${b.productId}|${b.locationId ?? ''}|${b.lotNumber ?? ''}|${b.id}`;
        return left < right ? -1 : left > right ? 1 : 0;
      });
      for (const line of sorted) {
        if (!UUID.test(line.id) || !UUID.test(line.productId) || !line.locationId || !UUID.test(line.locationId) ||
            !Number.isSafeInteger(line.expectedQuantity) || line.expectedQuantity <= 0 ||
            !Number.isSafeInteger(line.actualQuantity) || line.actualQuantity <= 0 ||
            (line.lotNumber !== null && (!line.lotNumber.trim() || line.lotNumber.length > 200)) ||
            (line.expiryDate !== null && Number.isNaN(line.expiryDate.getTime()))) {
          throw new Error('Invalid order line identity or quantity');
        }
        const matches = await tx.lockInventoryByIdentity(line.productId, line.locationId, line.lotNumber);
        // No implicit create: nullable lot uniqueness does not guarantee a single row.
        if (matches.length !== 1) throw new Error('Missing or ambiguous inventory identity');
        const item = matches[0];
        if (item.productId !== line.productId || item.locationId !== line.locationId ||
            item.lotNumber !== line.lotNumber || dateKey(item.expiryDate) !== dateKey(line.expiryDate)) {
          throw new Error('Inventory item identity mismatch');
        }
        const delta = input.type === 'INBOUND' ? line.actualQuantity : -line.actualQuantity;
        const balance = nextOnHand(item.quantityOnHand, delta);
        if (balance < item.quantityReserved) throw new Error('Insufficient available stock');
        await tx.updateOnHand(item.id, balance);
        await tx.appendLedger({ transactionType: input.type, inventoryItemId: item.id,
          productId: item.productId, locationId: item.locationId,
          delta, balance, actorId: principal.subjectId, orderId: order.id });
      }
      await tx.completeOrder(order.id, input.type);
      await tx.completeClaim({ scopeId: principal.scopeId, key: input.idempotencyKey,
        statusCode: 200, response: { orderId: order.id, movements: sorted.length } });
      return { kind: 'applied', orderId: order.id, movements: sorted.length };
    });
  }
}
