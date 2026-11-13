import { CanActivate, ExecutionContext, ForbiddenException, Injectable, SetMetadata } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { VerifiedPrincipal } from '../inventory-contract/inventory-command.service.js';
import type { AuthenticatedRequest } from './authentication.guard.js';

export type TrustedRole = NonNullable<VerifiedPrincipal['trustedRole']>;
export const TRUSTED_ROLES = 'trusted_roles';
export const RequireTrustedRoles = (...roles: TrustedRole[]) => SetMetadata(TRUSTED_ROLES, roles);

@Injectable()
export class TrustedRolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const roles = this.reflector.getAllAndOverride<TrustedRole[] | undefined>(TRUSTED_ROLES, [
      context.getHandler(), context.getClass(),
    ]);
    if (!roles?.length) throw new ForbiddenException('Authorization policy required');
    const principal = context.switchToHttp().getRequest<AuthenticatedRequest>().verifiedPrincipal;
    if (!principal?.trustedRole || !roles.includes(principal.trustedRole)) {
      throw new ForbiddenException('Insufficient permissions');
    }
    return true;
  }
}
