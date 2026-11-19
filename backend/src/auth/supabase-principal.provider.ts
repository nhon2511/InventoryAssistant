import { Inject, Injectable } from '@nestjs/common';
import {
  createRemoteJWKSet,
  decodeJwt,
  jwtVerify,
  type JWTVerifyGetKey,
  type JWTPayload,
} from 'jose';
import type {
  VerifiedPrincipal,
  VerifiedPrincipalProvider,
} from '../inventory-contract/inventory-command.service.js';

export type SupabaseJwtMode = 'jwks' | 'auth-server';

export interface SupabaseAuthOptions {
  /** Exact Supabase project origin; never an arbitrary URL supplied by a request. */
  projectUrl: string;
  mode: SupabaseJwtMode;
  /** Publishable/anon key used only for Auth /user in legacy symmetric mode. */
  publishableKey?: string;
  /** Enable only after Owner verifies app_metadata.wms_role provisioning. */
  trustAppMetadataRole?: boolean;
  timeoutMs?: number;
  jwks?: JWTVerifyGetKey;
  fetcher?: typeof fetch;
}

export const SUPABASE_AUTH_OPTIONS = 'SUPABASE_AUTH_OPTIONS';

export class InvalidAccessTokenError extends Error {
  constructor() {
    super('Invalid access token');
  }
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
const ROLES = new Set(['ADMIN', 'MANAGER', 'STAFF']);

@Injectable()
export class SupabasePrincipalProvider implements VerifiedPrincipalProvider {
  private readonly issuer: string;
  private readonly jwks?: JWTVerifyGetKey;
  private readonly fetcher: typeof fetch;

  constructor(@Inject(SUPABASE_AUTH_OPTIONS) private readonly options: SupabaseAuthOptions) {
    const url = new URL(options.projectUrl);
    if (url.protocol !== 'https:' || url.pathname !== '/' || url.search || url.hash || url.username || url.password) {
      throw new Error('Supabase project URL must be an HTTPS origin');
    }
    this.issuer = `${url.origin}/auth/v1`;
    if (options.mode === 'jwks') {
      this.jwks = options.jwks ?? createRemoteJWKSet(new URL(`${this.issuer}/.well-known/jwks.json`));
    } else if (options.mode === 'auth-server') {
      if (!options.publishableKey) throw new Error('Auth-server mode requires a publishable key');
    } else {
      throw new Error('Unsupported Supabase JWT verification mode');
    }
    this.fetcher = options.fetcher ?? fetch;
  }

  async verifyAccessToken(token: string): Promise<VerifiedPrincipal> {
    if (!token || token.length > 8192 || token.split('.').length !== 3) {
      throw new InvalidAccessTokenError();
    }
    try {
      const claims = this.options.mode === 'jwks'
        ? (await jwtVerify(token, this.jwks!, {
            issuer: this.issuer,
            audience: 'authenticated',
            algorithms: ['RS256', 'ES256'],
          })).payload
        : await this.verifyWithAuthServer(token);
      return this.toPrincipal(claims, this.options.mode === 'jwks' ? 'verified-jwt' : 'supabase-auth');
    } catch {
      // Never leak verification errors, raw JWTs or Supabase responses to callers.
      throw new InvalidAccessTokenError();
    }
  }

  private async verifyWithAuthServer(token: string): Promise<JWTPayload> {
    const response = await this.fetcher(`${this.issuer}/user`, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
        apikey: this.options.publishableKey!,
      },
      signal: AbortSignal.timeout(this.options.timeoutMs ?? 3000),
      cache: 'no-store',
    });
    if (!response.ok) throw new InvalidAccessTokenError();
    const user: unknown = await response.json();
    const claims = decodeJwt(token);
    if (!user || typeof user !== 'object' || !('id' in user) || user.id !== claims.sub) {
      throw new InvalidAccessTokenError();
    }
    return claims;
  }

  private toPrincipal(claims: JWTPayload, authorizationSource: VerifiedPrincipal['authorizationSource']): VerifiedPrincipal {
    const audience = Array.isArray(claims.aud) ? claims.aud : [claims.aud];
    const now = Math.floor(Date.now() / 1000);
    if (!UUID.test(claims.sub ?? '') || claims.iss !== this.issuer ||
        audience.length !== 1 || audience[0] !== 'authenticated' ||
        typeof claims.exp !== 'number' || claims.exp <= now ||
        (typeof claims.nbf === 'number' && claims.nbf > now) ||
        claims.role !== 'authenticated') {
      throw new InvalidAccessTokenError();
    }
    const principal: VerifiedPrincipal = {
      subjectId: claims.sub!, scopeId: claims.sub!, issuer: this.issuer,
      audience: 'authenticated', authorizationSource,
    };
    const metadata: unknown = claims.app_metadata;
    if (this.options.trustAppMetadataRole && metadata && typeof metadata === 'object' &&
        'wms_role' in metadata && typeof metadata.wms_role === 'string' && ROLES.has(metadata.wms_role)) {
      principal.trustedRole = metadata.wms_role as VerifiedPrincipal['trustedRole'];
    }
    return principal;
  }
}
