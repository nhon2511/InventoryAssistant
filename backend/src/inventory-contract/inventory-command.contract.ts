import { createHash } from 'node:crypto';

// Offline contract only: no Prisma adapter, endpoint, or Cloud query is wired in.
export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue };

function canonicalJson(value: JsonValue): string {
  if (value === null || typeof value === 'boolean' || typeof value === 'string') {
    return JSON.stringify(value);
  }
  if (typeof value === 'number') {
    if (!Number.isFinite(value)) throw new Error('Request body must be finite JSON');
    return JSON.stringify(value);
  }
  if (Array.isArray(value)) {
    return `[${value.map(canonicalJson).join(',')}]`;
  }
  if (Object.getPrototypeOf(value) !== Object.prototype) {
    throw new Error('Request body must be plain JSON');
  }
  return `{${Object.keys(value)
    .sort()
    .map((key) => `${JSON.stringify(key)}:${canonicalJson(value[key])}`)
    .join(',')}}`;
}

export function requestFingerprint(
  method: string,
  path: string,
  body: JsonValue,
): string {
  if (!/^(POST|PUT|PATCH|DELETE)$/.test(method) || !path.startsWith('/')) {
    throw new Error('Invalid idempotent request metadata');
  }
  return createHash('sha256')
    .update(`${method}\n${path}\n${canonicalJson(body)}`, 'utf8')
    .digest('hex');
}

export interface IdempotencyRecord {
  httpMethod: string;
  requestPath: string;
  requestHash: string;
  processingStatus: 'processing' | 'completed';
  statusCode: number | null;
  response: JsonValue | null;
  expiresAt: Date;
}

export type ClaimDecision =
  | { kind: 'claimed' }
  | { kind: 'conflict' }
  | { kind: 'in_progress' }
  | { kind: 'expired' }
  | { kind: 'replay'; statusCode: number; response: JsonValue | null };

export function decideClaim(
  existing: IdempotencyRecord | null,
  request: { method: string; path: string; hash: string },
  now: Date,
): ClaimDecision {
  if (!existing) return { kind: 'claimed' };
  if (
    existing.httpMethod !== request.method ||
    existing.requestPath !== request.path ||
    existing.requestHash !== request.hash
  ) {
    return { kind: 'conflict' };
  }
  // Expired keys cannot be silently recycled while their side effect persists.
  if (existing.expiresAt <= now) return { kind: 'expired' };
  if (existing.processingStatus === 'processing') return { kind: 'in_progress' };
  if (existing.statusCode === null) throw new Error('Corrupt idempotency record');
  return {
    kind: 'replay',
    statusCode: existing.statusCode,
    response: existing.response,
  };
}

export function nextOnHand(current: number, delta: number): number {
  if (!Number.isSafeInteger(current) || !Number.isSafeInteger(delta) || delta === 0) {
    throw new Error('Inventory quantity must be a nonzero safe integer delta');
  }
  const next = current + delta;
  if (!Number.isSafeInteger(next) || next < 0 || next > 2147483647) {
    throw new Error('Inventory quantity would be outside PostgreSQL int4 range');
  }
  return next;
}

export function assertApproverRole(role: string): void {
  if (role !== 'ADMIN' && role !== 'MANAGER') {
    throw new Error('Approval requires ADMIN or MANAGER');
  }
}

export interface LockedInventoryItem {
  id: string;
  productId: string;
  locationId: string;
  quantityOnHand: number;
  quantityReserved: number;
}

export interface MovementCommand {
  transactionType: 'INBOUND' | 'OUTBOUND';
  scopeId: string;
  key: string;
  method: 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  path: string;
  body: JsonValue;
  inventoryItemId: string;
  productId: string;
  locationId: string;
  delta: number;
  actorId: string;
  orderId?: string;
  now: Date;
  expiresAt: Date;
}

export interface InventoryTransactionPort {
  // Adapter must INSERT claim with ON CONFLICT DO NOTHING, then SELECT FOR UPDATE
  // on conflict, all within this transaction. Return null only for inserted claim.
  claimOrLock(input: {
    scopeId: string;
    key: string;
    method: string;
    path: string;
    hash: string;
    now: Date;
    expiresAt: Date;
  }): Promise<IdempotencyRecord | null>;
  // Adapter must SELECT inventory_items FOR UPDATE, not a plain Prisma findUnique.
  lockInventory(itemId: string): Promise<LockedInventoryItem>;
  updateOnHand(itemId: string, balance: number): Promise<void>;
  appendLedger(input: {
    transactionType: 'INBOUND' | 'OUTBOUND';
    inventoryItemId: string;
    productId: string;
    locationId: string;
    delta: number;
    balance: number;
    actorId: string;
    orderId?: string;
  }): Promise<void>;
  completeClaim(input: {
    scopeId: string;
    key: string;
    statusCode: number;
    response: JsonValue;
  }): Promise<void>;
}

export interface InventoryTransactionRunner {
  transaction<T>(work: (tx: InventoryTransactionPort) => Promise<T>): Promise<T>;
}

export type MovementResult =
  | { kind: 'applied'; balance: number }
  | Exclude<ClaimDecision, { kind: 'claimed' }>;

export async function executeMovementContract(
  runner: InventoryTransactionRunner,
  command: MovementCommand,
): Promise<MovementResult> {
  if (!command.scopeId || !command.key || !command.actorId) {
    throw new Error('Authenticated scope, key and actor are required');
  }
  if (
    (command.transactionType === 'INBOUND' && command.delta <= 0) ||
    (command.transactionType === 'OUTBOUND' && command.delta >= 0)
  ) {
    throw new Error('Movement type and delta sign disagree');
  }
  if (command.expiresAt <= command.now) {
    throw new Error('Idempotency expiry must be in the future');
  }
  const hash = requestFingerprint(command.method, command.path, command.body);
  return runner.transaction(async (tx) => {
    const existing = await tx.claimOrLock({
      scopeId: command.scopeId,
      key: command.key,
      method: command.method,
      path: command.path,
      hash,
      now: command.now,
      expiresAt: command.expiresAt,
    });
    const decision = decideClaim(
      existing,
      { method: command.method, path: command.path, hash },
      command.now,
    );
    if (decision.kind !== 'claimed') return decision;

    const item = await tx.lockInventory(command.inventoryItemId);
    if (
      item.id !== command.inventoryItemId ||
      item.productId !== command.productId ||
      item.locationId !== command.locationId
    ) {
      throw new Error('Ledger item/product/location mismatch');
    }
    const balance = nextOnHand(item.quantityOnHand, command.delta);
    if (balance < item.quantityReserved) {
      throw new Error('Movement would over-reserve inventory');
    }
    await tx.updateOnHand(item.id, balance);
    await tx.appendLedger({
      transactionType: command.transactionType,
      inventoryItemId: item.id,
      productId: item.productId,
      locationId: item.locationId,
      delta: command.delta,
      balance,
      actorId: command.actorId,
      orderId: command.orderId,
    });
    // Cache only a small, explicitly non-sensitive response.
    await tx.completeClaim({
      scopeId: command.scopeId,
      key: command.key,
      statusCode: 200,
      response: { inventoryItemId: item.id, balance },
    });
    return { kind: 'applied', balance };
  });
}
