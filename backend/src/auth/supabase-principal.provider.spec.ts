import { describe, expect, it, vi } from 'vitest';
import { createLocalJWKSet, exportJWK, generateKeyPair, SignJWT } from 'jose';
import { SupabasePrincipalProvider } from './supabase-principal.provider.js';

const PROJECT = 'https://example.supabase.co';
const ISSUER = `${PROJECT}/auth/v1`;
const SUBJECT = '123e4567-e89b-42d3-a456-426614174000';

async function fixture() {
  const keys = await generateKeyPair('ES256');
  const jwk = await exportJWK(keys.publicKey);
  jwk.kid = 'offline-key';
  const jwks = createLocalJWKSet({ keys: [jwk] });
  const sign = async (overrides: {
    issuer?: string; audience?: string; expires?: number;
    role?: string; appRole?: string; userRole?: string;
  } = {}) => new SignJWT({
    role: overrides.role ?? 'authenticated',
    app_metadata: { wms_role: overrides.appRole },
    user_metadata: { wms_role: overrides.userRole },
  }).setProtectedHeader({ alg: 'ES256', kid: 'offline-key' })
    .setIssuer(overrides.issuer ?? ISSUER)
    .setAudience(overrides.audience ?? 'authenticated')
    .setSubject(SUBJECT)
    .setIssuedAt()
    .setExpirationTime(overrides.expires ?? Math.floor(Date.now() / 1000) + 300)
    .sign(keys.privateKey);
  const provider = new SupabasePrincipalProvider({ projectUrl: PROJECT, mode: 'jwks', jwks });
  return { provider, sign, jwks };
}

describe('Supabase verified principal', () => {
  it('accepts a signed Supabase access JWT and scopes to the subject', async () => {
    const f = await fixture();
    await expect(f.provider.verifyAccessToken(await f.sign())).resolves.toEqual({
      subjectId: SUBJECT, scopeId: SUBJECT, issuer: ISSUER,
      audience: 'authenticated', authorizationSource: 'verified-jwt',
    });
  });

  it('rejects malformed, wrong signature, expired, issuer, audience and non-user role', async () => {
    const f = await fixture();
    await expect(f.provider.verifyAccessToken('bad')).rejects.toThrow('Invalid access token');
    const other = await fixture();
    await expect(f.provider.verifyAccessToken(await other.sign())).rejects.toThrow('Invalid access token');
    for (const token of [
      await f.sign({ expires: Math.floor(Date.now() / 1000) - 10 }),
      await f.sign({ issuer: 'https://other.supabase.co/auth/v1' }),
      await f.sign({ audience: 'anon' }),
      await f.sign({ role: 'service_role' }),
    ]) await expect(f.provider.verifyAccessToken(token)).rejects.toThrow('Invalid access token');
  });

  it('ignores forged user_metadata and top-level business roles; app role is opt-in', async () => {
    const f = await fixture();
    const token = await f.sign({ userRole: 'ADMIN', role: 'authenticated', appRole: 'MANAGER' });
    expect((await f.provider.verifyAccessToken(token)).trustedRole).toBeUndefined();
    const authorized = new SupabasePrincipalProvider({
      projectUrl: PROJECT, mode: 'jwks', jwks: f.jwks, trustAppMetadataRole: true,
    });
    expect((await authorized.verifyAccessToken(token)).trustedRole).toBe('MANAGER');
    const userOnly = await f.sign({ userRole: 'ADMIN' });
    expect((await authorized.verifyAccessToken(userOnly)).trustedRole).toBeUndefined();
  });

  it('legacy mode accepts only Auth /user validated tokens and fails closed on errors', async () => {
    const f = await fixture();
    const token = await f.sign();
    const fetcher = vi.fn<typeof fetch>().mockResolvedValue(new Response(JSON.stringify({ id: SUBJECT }), { status: 200 }));
    const provider = new SupabasePrincipalProvider({
      projectUrl: PROJECT, mode: 'auth-server', publishableKey: 'test-publishable', fetcher,
    });
    expect((await provider.verifyAccessToken(token)).authorizationSource).toBe('supabase-auth');
    expect(fetcher).toHaveBeenCalledWith(`${ISSUER}/user`, expect.objectContaining({ method: 'GET', cache: 'no-store' }));
    fetcher.mockResolvedValueOnce(new Response('{}', { status: 401 }));
    await expect(provider.verifyAccessToken(token)).rejects.toThrow('Invalid access token');
    fetcher.mockRejectedValueOnce(new Error('network failure'));
    await expect(provider.verifyAccessToken(token)).rejects.toThrow('Invalid access token');
    fetcher.mockResolvedValueOnce(new Response(JSON.stringify({ id: 'other' }), { status: 200 }));
    await expect(provider.verifyAccessToken(token)).rejects.toThrow('Invalid access token');
  });
});
