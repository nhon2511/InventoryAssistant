import { describe, it, expect } from 'vitest';
import { Test } from '@nestjs/testing';
import { ConfigModule } from '@nestjs/config';
import { AuthModule } from './auth.module.js';
import { VERIFIED_PRINCIPAL_PROVIDER, type VerifiedPrincipalProvider } from '../inventory-contract/inventory-command.service.js';
import { SupabasePrincipalProvider } from './supabase-principal.provider.js';

describe('AuthModule', () => {
  it('provides SupabasePrincipalProvider as VERIFIED_PRINCIPAL_PROVIDER', async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({ SUPABASE_URL: 'https://test-project.supabase.co/' })],
        }),
        AuthModule,
      ],
    }).compile();

    const provider = moduleRef.get<VerifiedPrincipalProvider>(VERIFIED_PRINCIPAL_PROVIDER);
    expect(provider).toBeInstanceOf(SupabasePrincipalProvider);
  });

  it('throws when SUPABASE_URL is missing', async () => {
    await expect(
      Test.createTestingModule({
        imports: [
          ConfigModule.forRoot({
            isGlobal: true,
            ignoreEnvFile: true,
            load: [() => ({})],
          }),
          AuthModule,
        ],
      }).compile(),
    ).rejects.toThrow('SUPABASE_URL is required');
  });
});
