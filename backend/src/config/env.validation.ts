import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import {
  IsEnum,
  IsNumber,
  IsOptional,
  IsString,
  IsUrl,
  validateSync,
} from 'class-validator';

export enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
  Staging = 'staging',
}

export class EnvironmentVariables {
  @IsEnum(Environment)
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @IsNumber()
  @IsOptional()
  PORT: number = 3000;

  @IsString()
  @IsOptional()
  API_PREFIX: string = '/api/v1';

  @IsString()
  DATABASE_URL: string = 'postgresql://postgres:postgres@localhost:5432/postgres';

  @IsString()
  @IsOptional()
  DIRECT_URL?: string;

  @IsUrl({ require_tld: false })
  @IsOptional()
  SUPABASE_URL: string = 'https://example.supabase.co';

  @IsString()
  @IsOptional()
  SUPABASE_ANON_KEY: string = 'test-anon-key';

  @IsString()
  @IsOptional()
  SUPABASE_SERVICE_ROLE_KEY?: string;

  @IsString()
  @IsOptional()
  SUPABASE_JWT_SECRET: string = 'test-jwt-secret';

  @IsString()
  @IsOptional()
  CORS_ORIGINS: string = '*';
}

export function validateEnvironment(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    throw new Error(`Environment validation failed: ${errors.toString()}`);
  }

  return validatedConfig;
}
