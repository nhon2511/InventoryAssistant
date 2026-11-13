import { CanActivate, ExecutionContext, Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { VERIFIED_PRINCIPAL_PROVIDER, type VerifiedPrincipal, type VerifiedPrincipalProvider } from '../inventory-contract/inventory-command.service.js';

export interface AuthenticatedRequest {
  headers: { authorization?: string | string[] };
  verifiedPrincipal?: VerifiedPrincipal;
}

export function bearerToken(header: string | string[] | undefined): string {
  if (typeof header !== 'string') throw new UnauthorizedException('Authentication required');
  const match = /^Bearer ([A-Za-z0-9_~-]+\.[A-Za-z0-9_~-]+\.[A-Za-z0-9_~-]+)$/.exec(header);
  if (!match) throw new UnauthorizedException('Authentication required');
  return match[1];
}

@Injectable()
export class JwtAuthenticationGuard implements CanActivate {
  constructor(@Inject(VERIFIED_PRINCIPAL_PROVIDER) private readonly principals: VerifiedPrincipalProvider) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    delete request.verifiedPrincipal;
    try {
      request.verifiedPrincipal = await this.principals.verifyAccessToken(bearerToken(request.headers.authorization));
      return true;
    } catch {
      throw new UnauthorizedException('Authentication required');
    }
  }
}
