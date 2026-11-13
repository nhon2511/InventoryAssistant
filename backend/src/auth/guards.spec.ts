import { describe, expect, it, vi } from 'vitest';
import { Reflector } from '@nestjs/core';
import type { ExecutionContext } from '@nestjs/common';
import type { VerifiedPrincipal } from '../inventory-contract/inventory-command.service.js';
import { bearerToken, JwtAuthenticationGuard, type AuthenticatedRequest } from './authentication.guard.js';
import { RequireTrustedRoles, TrustedRolesGuard } from './trusted-roles.guard.js';

function context(request: AuthenticatedRequest): ExecutionContext {
  return {
    switchToHttp: () => ({ getRequest: () => request }),
    getHandler: () => handler,
    getClass: () => Controller,
  } as unknown as ExecutionContext;
}
class Controller {}
function handler() {}
const principal: VerifiedPrincipal = {
  subjectId: 'user', scopeId: 'user', issuer: 'issuer',
  audience: 'authenticated', authorizationSource: 'verified-jwt',
};

describe('authentication and trusted-role guards', () => {
  it('rejects missing or malformed Bearer headers', () => {
    for (const header of [undefined, '', 'Basic x', 'Bearer x', 'Bearer x.y.z extra', ['Bearer x.y.z']]) {
      expect(() => bearerToken(header)).toThrow('Authentication required');
    }
    expect(bearerToken('Bearer a.b.c')).toBe('a.b.c');
  });

  it('attaches only verified principals and maps failures to generic 401', async () => {
    const verifyAccessToken = vi.fn().mockResolvedValueOnce(principal).mockRejectedValueOnce(new Error('secret detail'));
    const guard = new JwtAuthenticationGuard({ verifyAccessToken });
    const request: AuthenticatedRequest = { headers: { authorization: 'Bearer a.b.c' } };
    await expect(guard.canActivate(context(request))).resolves.toBe(true);
    expect(request.verifiedPrincipal).toBe(principal);
    await expect(guard.canActivate(context({ headers: { authorization: 'Bearer a.b.c' } })))
      .rejects.toThrow('Authentication required');
    expect(verifyAccessToken).toHaveBeenCalledWith('a.b.c');
  });

  it('requires explicit policy and trusted ADMIN/MANAGER; rejects STAFF or missing role', () => {
    const reflector = new Reflector();
    const guard = new TrustedRolesGuard(reflector);
    expect(() => guard.canActivate(context({ headers: {}, verifiedPrincipal: principal }))).toThrow('Authorization policy required');
    RequireTrustedRoles('ADMIN', 'MANAGER')(handler);
    for (const trustedRole of [undefined, 'STAFF'] as const) {
      expect(() => guard.canActivate(context({ headers: {}, verifiedPrincipal: { ...principal, trustedRole } })))
        .toThrow('Insufficient permissions');
    }
    for (const trustedRole of ['ADMIN', 'MANAGER'] as const) {
      expect(guard.canActivate(context({ headers: {}, verifiedPrincipal: { ...principal, trustedRole } }))).toBe(true);
    }
  });
});
