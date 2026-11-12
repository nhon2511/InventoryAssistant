import 'reflect-metadata';
import { Transform, Type, plainToInstance } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  Matches,
  Max,
  Min,
  ValidationError,
  validateSync,
} from 'class-validator';

export enum Environment {
  Development = 'development',
  Production = 'production',
  Test = 'test',
  Staging = 'staging',
}

const POSTGRES_URI_REGEX = /^(postgres|postgresql):\/\/.+/;
const API_PREFIX_REGEX = /^\/[a-zA-Z0-9_-]+(\/[a-zA-Z0-9_-]+)*$/;

export class EnvironmentVariables {
  @IsEnum(Environment, {
    message: 'NODE_ENV must be one of: development, production, test, staging',
  })
  @IsOptional()
  NODE_ENV: Environment = Environment.Development;

  @Type(() => Number)
  @IsInt({ message: 'PORT must be an integer' })
  @Min(1, { message: 'PORT must be at least 1' })
  @Max(65535, { message: 'PORT must be at most 65535' })
  @IsOptional()
  PORT: number = 3000;

  @Transform(({ value }) => {
    if (typeof value !== 'string') return value;
    const trimmed = value.trim().replace(/^\/+/, '').replace(/\/+$/, '');
    return trimmed ? `/${trimmed}` : '/api/v1';
  })
  @IsString({ message: 'API_PREFIX must be a string' })
  @Matches(API_PREFIX_REGEX, {
    message: 'API_PREFIX must be a valid path (e.g. /api/v1)',
  })
  @IsOptional()
  API_PREFIX: string = '/api/v1';

  @IsNotEmpty({ message: 'DATABASE_URL is required' })
  @IsString({ message: 'DATABASE_URL must be a string' })
  @Matches(POSTGRES_URI_REGEX, {
    message:
      'DATABASE_URL must be a valid PostgreSQL connection URI (e.g. postgresql://user:password@host:port/dbname)',
  })
  DATABASE_URL!: string;

  @IsOptional()
  @IsString({ message: 'DIRECT_URL must be a string' })
  @Matches(POSTGRES_URI_REGEX, {
    message:
      'DIRECT_URL must be a valid PostgreSQL connection URI (e.g. postgresql://user:password@host:port/dbname)',
  })
  DIRECT_URL?: string;

  @IsOptional()
  @IsUrl(
    { require_tld: false, require_protocol: true },
    { message: 'SUPABASE_URL must be a valid URL' },
  )
  SUPABASE_URL?: string;

  @IsOptional()
  @IsString({ message: 'SUPABASE_ANON_KEY must be a string' })
  SUPABASE_ANON_KEY?: string;

  @IsOptional()
  @IsString({ message: 'SUPABASE_SERVICE_ROLE_KEY must be a string' })
  SUPABASE_SERVICE_ROLE_KEY?: string;

  @IsOptional()
  @IsString({ message: 'SUPABASE_JWT_SECRET must be a string' })
  SUPABASE_JWT_SECRET?: string;

  @IsOptional()
  @IsString({ message: 'CORS_ORIGINS must be a string' })
  CORS_ORIGINS: string = '*';
}

export function formatValidationErrors(errors: ValidationError[]): string {
  return errors
    .map((err) => {
      const constraints = err.constraints
        ? Object.values(err.constraints).join(', ')
        : 'Invalid value';
      return `Property "${err.property}": ${constraints}`;
    })
    .join('; ');
}

export function validateEnvironment(config: Record<string, unknown>) {
  const validatedConfig = plainToInstance(EnvironmentVariables, config, {
    enableImplicitConversion: true,
  });

  const errors = validateSync(validatedConfig, {
    skipMissingProperties: false,
  });

  if (errors.length > 0) {
    const formatted = formatValidationErrors(errors);
    throw new Error(`Environment validation failed: ${formatted}`);
  }

  return validatedConfig;
}
