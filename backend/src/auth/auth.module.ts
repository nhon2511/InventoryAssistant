import { Module } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { VERIFIED_PRINCIPAL_PROVIDER } from '../inventory-contract/inventory-command.service.js';
import {
  SUPABASE_AUTH_OPTIONS,
  SupabasePrincipalProvider,
  type SupabaseAuthOptions,
} from './supabase-principal.provider.js';

@Module({
  providers: [
    {
      provide: SUPABASE_AUTH_OPTIONS,
      useFactory: (config: ConfigService): SupabaseAuthOptions => {
        const supabaseUrl = config.get<string>('SUPABASE_URL');
        if (!supabaseUrl) {
          throw new Error('SUPABASE_URL is required for authentication');
        }
        return {
          projectUrl: supabaseUrl,
          mode: 'jwks',
          trustAppMetadataRole: true,
        };
      },
      inject: [ConfigService],
    },
    {
      provide: SupabasePrincipalProvider,
      useClass: SupabasePrincipalProvider,
    },
    {
      provide: VERIFIED_PRINCIPAL_PROVIDER,
      useExisting: SupabasePrincipalProvider,
    },
  ],
  exports: [VERIFIED_PRINCIPAL_PROVIDER, SupabasePrincipalProvider],
})
export class AuthModule {}
