import { describe, expect, it, vi } from 'vitest';
import type {
  InventoryTransactionPort,
  InventoryTransactionRunner,
} from './inventory-command.contract.js';
import {
  InventoryCommandService,
  type VerifiedPrincipalProvider,
} from './inventory-command.service.js';

function fixture(role?: 'ADMIN' | 'MANAGER' | 'STAFF') {
  const claims: Array<{ scopeId: string; key: string }> = [];
  const ledger: Array<{ transactionType: string; actorId: string; delta: number }> = [];
  const tx: InventoryTransactionPort = {
    claimOrLock: async (input) => {
      claims.push({ scopeId: input.scopeId, key: input.key });
      return null;
    },
    lockInventory: async (id) => ({
      id, productId: 'product-1', locationId: 'location-1',
      quantityOnHand: 5, quantityReserved: 1,
    }),
    updateOnHand: async () => {},
    appendLedger: async (input) => {
      ledger.push({ transactionType: input.transactionType,
        actorId: input.actorId, delta: input.delta });
    },
    completeClaim: async () => {},
  };
  const runner: InventoryTransactionRunner = {
    transaction: vi.fn(async (work) => work(tx)),
  };
  const verifyAccessToken = vi.fn(async (_token: string) => ({
    subjectId: 'verified-actor', scopeId: 'verified-scope', trustedRole: role,
    issuer: 'https://example.supabase.co/auth/v1', audience: 'authenticated',
    authorizationSource: 'verified-jwt' as const,
  }));
  const principals: VerifiedPrincipalProvider = { verifyAccessToken };
  const service = new InventoryCommandService(
    runner, principals, () => new Date('2026-11-13T00:00:00Z'),
  );
  return { service, runner, verifyAccessToken, claims, ledger };
}

const input = {
  idempotencyKey: 'key-1', inventoryItemId: 'item-1',
  productId: 'product-1', locationId: 'location-1', quantity: 2,
};

describe('unwired inventory service with verified-principal port', () => {
  it('derives scope/actor from provider and maps inbound/outbound signs', async () => {
    const f = fixture();
    await expect(f.service.receive('verified-token', input)).resolves.toEqual({
      kind: 'applied', balance: 7,
    });
    await expect(f.service.ship('verified-token', { ...input, idempotencyKey: 'key-2' })).resolves.toEqual({
      kind: 'applied', balance: 3,
    });
    expect(f.verifyAccessToken).toHaveBeenCalledWith('verified-token');
    expect(f.claims).toEqual([
      { scopeId: 'verified-scope', key: 'key-1' },
      { scopeId: 'verified-scope', key: 'key-2' },
    ]);
    expect(f.ledger).toEqual([
      { transactionType: 'INBOUND', actorId: 'verified-actor', delta: 2 },
      { transactionType: 'OUTBOUND', actorId: 'verified-actor', delta: -2 },
    ]);
  });

  it('fails closed before a transaction when identity or quantity is invalid', async () => {
    const f = fixture();
    f.verifyAccessToken.mockRejectedValueOnce(new Error('invalid signature'));
    await expect(f.service.receive('bad-token', input)).rejects.toThrow('invalid signature');
    await expect(f.service.receive('token', { ...input, quantity: 0 })).rejects.toThrow();
    await expect(f.service.receive('token', { ...input, idempotencyKey: '' })).rejects.toThrow();
    expect(f.runner.transaction).not.toHaveBeenCalled();
  });

  it('rejects approval without a trusted role or for STAFF', async () => {
    await expect(fixture().service.authorizeApproval('token')).rejects.toThrow('Trusted approval authority');
    await expect(fixture('STAFF').service.authorizeApproval('token')).rejects.toThrow('ADMIN or MANAGER');
    await expect(fixture('MANAGER').service.authorizeApproval('token')).resolves.toBe('verified-actor');
  });
});
