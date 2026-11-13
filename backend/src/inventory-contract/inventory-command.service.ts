import {
  assertApproverRole,
  executeMovementContract,
  type InventoryTransactionPort,
  type InventoryTransactionRunner,
  type MovementResult,
} from './inventory-command.contract.js';

export interface VerifiedPrincipal {
  subjectId: string;
  scopeId: string;
  issuer: string;
  audience: string;
  authorizationSource: 'verified-jwt' | 'supabase-auth';
  // Only a verified server-side authority may set this. Never user_metadata
  // or the currently client-writable public.profiles.role column.
  trustedRole?: 'ADMIN' | 'MANAGER' | 'STAFF';
}

export interface VerifiedPrincipalProvider {
  verifyAccessToken(token: string): Promise<VerifiedPrincipal>;
}

export const VERIFIED_PRINCIPAL_PROVIDER = 'VERIFIED_PRINCIPAL_PROVIDER';

export interface InventoryMovementInput {
  idempotencyKey: string;
  inventoryItemId: string;
  productId: string;
  locationId: string;
  quantity: number;
  orderId?: string;
}

// Future workflow methods must use the same authenticated principal and tx.
// No reservation/order-state implementation is exposed until workflow audit.
export interface InventoryWorkflowTransactionPort extends InventoryTransactionPort {
  updateReserved(itemId: string, quantityReserved: number): Promise<void>;
  lockOrder(orderId: string): Promise<{ id: string; status: string }>;
  updateOrderStatus(orderId: string, expectedStatus: string, nextStatus: string): Promise<void>;
}

export interface InventoryWorkflowRepository {
  reserveWithinTransaction(tx: InventoryWorkflowTransactionPort, input: {
    inventoryItemId: string;
    quantity: number;
    principal: VerifiedPrincipal;
  }): Promise<void>;
  transitionOrderWithinTransaction(tx: InventoryWorkflowTransactionPort, input: {
    orderId: string;
    expectedStatus: string;
    nextStatus: string;
    principal: VerifiedPrincipal;
  }): Promise<void>;
}

// Deliberately not registered in AppModule: no trusted provider or Cloud tables.
export class InventoryCommandService {
  constructor(
    private readonly transactions: InventoryTransactionRunner,
    private readonly principals: VerifiedPrincipalProvider,
    private readonly now: () => Date = () => new Date(),
  ) {}

  private async move(
    token: string,
    input: InventoryMovementInput,
    transactionType: 'INBOUND' | 'OUTBOUND',
  ): Promise<MovementResult> {
    const principal = await this.principals.verifyAccessToken(token);
    if (!principal.subjectId || !principal.scopeId) {
      throw new Error('Verified principal is required');
    }
    if (!Number.isSafeInteger(input.quantity) || input.quantity <= 0) {
      throw new Error('Movement quantity must be a positive integer');
    }
    if (input.idempotencyKey.length < 1 || input.idempotencyKey.length > 200) {
      throw new Error('Invalid idempotency key length');
    }
    const timestamp = this.now();
    const delta = transactionType === 'INBOUND' ? input.quantity : -input.quantity;
    // This body is a small canonical fingerprint, never a raw HTTP body/token.
    const body = {
      inventoryItemId: input.inventoryItemId,
      productId: input.productId,
      locationId: input.locationId,
      quantity: input.quantity,
      orderId: input.orderId ?? null,
      transactionType,
    };
    return executeMovementContract(this.transactions, {
      transactionType,
      scopeId: principal.scopeId,
      actorId: principal.subjectId,
      key: input.idempotencyKey,
      method: 'POST',
      path: '/backend/inventory/movements',
      body,
      inventoryItemId: input.inventoryItemId,
      productId: input.productId,
      locationId: input.locationId,
      orderId: input.orderId,
      delta,
      now: timestamp,
      expiresAt: new Date(timestamp.getTime() + 24 * 60 * 60 * 1000),
    });
  }

  receive(token: string, input: InventoryMovementInput): Promise<MovementResult> {
    return this.move(token, input, 'INBOUND');
  }

  ship(token: string, input: InventoryMovementInput): Promise<MovementResult> {
    return this.move(token, input, 'OUTBOUND');
  }

  async authorizeApproval(token: string): Promise<string> {
    const principal = await this.principals.verifyAccessToken(token);
    if (!principal.subjectId || !principal.trustedRole) {
      throw new Error('Trusted approval authority is unavailable');
    }
    assertApproverRole(principal.trustedRole);
    return principal.subjectId;
  }
}
