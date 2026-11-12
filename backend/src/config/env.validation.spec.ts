import { describe, expect, it } from 'vitest';
import {
  Environment,
  formatValidationErrors,
  validateEnvironment,
} from './env.validation.js';

describe('validateEnvironment', () => {
  const validDbUrl = 'postgresql://postgres:my-secret-password@localhost:5432/postgres';

  it('should validate and supply defaults when only valid DATABASE_URL is provided', () => {
    const config = {
      DATABASE_URL: validDbUrl,
    };
    const validated = validateEnvironment(config);

    expect(validated.DATABASE_URL).toBe(validDbUrl);
    expect(validated.PORT).toBe(3000);
    expect(validated.NODE_ENV).toBe(Environment.Development);
    expect(validated.API_PREFIX).toBe('/api/v1');
    expect(validated.CORS_ORIGINS).toBe('*');
    // Ensure no fake credentials are used as defaults
    expect(validated.SUPABASE_URL).toBeUndefined();
    expect(validated.SUPABASE_ANON_KEY).toBeUndefined();
    expect(validated.SUPABASE_SERVICE_ROLE_KEY).toBeUndefined();
    expect(validated.SUPABASE_JWT_SECRET).toBeUndefined();
    expect(validated.DIRECT_URL).toBeUndefined();
  });

  it('should throw error when DATABASE_URL is missing', () => {
    const config = {};
    expect(() => validateEnvironment(config)).toThrow(
      /Property "DATABASE_URL"/,
    );
  });

  it('should throw error when DATABASE_URL is empty', () => {
    const config = { DATABASE_URL: '' };
    expect(() => validateEnvironment(config)).toThrow(
      /Property "DATABASE_URL"/,
    );
  });

  it('should throw error when DATABASE_URL is not a valid PostgreSQL URI', () => {
    const config = {
      DATABASE_URL: 'mysql://root:root@localhost:3306/db',
    };
    expect(() => validateEnvironment(config)).toThrow(
      /DATABASE_URL must be a valid PostgreSQL connection URI/,
    );
  });

  it('should accept postgres:// and postgresql:// schemes for DATABASE_URL and DIRECT_URL', () => {
    const config = {
      DATABASE_URL: 'postgres://user:pass@db.example.com:5432/app',
      DIRECT_URL: 'postgresql://user:pass@direct.example.com:5432/app',
    };
    const validated = validateEnvironment(config);
    expect(validated.DATABASE_URL).toBe('postgres://user:pass@db.example.com:5432/app');
    expect(validated.DIRECT_URL).toBe('postgresql://user:pass@direct.example.com:5432/app');
  });

  it('should throw error when DIRECT_URL is invalid', () => {
    const config = {
      DATABASE_URL: validDbUrl,
      DIRECT_URL: 'not-a-valid-uri',
    };
    expect(() => validateEnvironment(config)).toThrow(
      /Property "DIRECT_URL"/,
    );
  });

  it('should parse custom port as number and validate bounds', () => {
    const config = {
      DATABASE_URL: validDbUrl,
      PORT: '8080',
    };
    const validated = validateEnvironment(config);
    expect(validated.PORT).toBe(8080);
  });

  it('should throw error when PORT is out of range or not an integer', () => {
    expect(() =>
      validateEnvironment({ DATABASE_URL: validDbUrl, PORT: 0 }),
    ).toThrow(/PORT must be at least 1/);

    expect(() =>
      validateEnvironment({ DATABASE_URL: validDbUrl, PORT: 70000 }),
    ).toThrow(/PORT must be at most 65535/);

    expect(() =>
      validateEnvironment({ DATABASE_URL: validDbUrl, PORT: 'abc' }),
    ).toThrow(/PORT must be an integer/);
  });

  it('should throw error for invalid environment enum', () => {
    const config = {
      NODE_ENV: 'invalid_env',
      DATABASE_URL: validDbUrl,
    };
    expect(() => validateEnvironment(config)).toThrow(
      /NODE_ENV must be one of/,
    );
  });

  it('should validate API_PREFIX format', () => {
    expect(() =>
      validateEnvironment({
        DATABASE_URL: validDbUrl,
        API_PREFIX: 'api/v1', // missing leading slash
      }),
    ).toThrow(/API_PREFIX must start with \/ and not end with \//);

    expect(() =>
      validateEnvironment({
        DATABASE_URL: validDbUrl,
        API_PREFIX: '/api/v1/', // trailing slash
      }),
    ).toThrow(/API_PREFIX must start with \/ and not end with \//);

    const valid = validateEnvironment({
      DATABASE_URL: validDbUrl,
      API_PREFIX: '/custom/api',
    });
    expect(valid.API_PREFIX).toBe('/custom/api');
  });

  it('should validate SUPABASE_URL if provided', () => {
    expect(() =>
      validateEnvironment({
        DATABASE_URL: validDbUrl,
        SUPABASE_URL: 'not-a-url',
      }),
    ).toThrow(/SUPABASE_URL must be a valid URL/);

    const valid = validateEnvironment({
      DATABASE_URL: validDbUrl,
      SUPABASE_URL: 'https://xyzcompany.supabase.co',
    });
    expect(valid.SUPABASE_URL).toBe('https://xyzcompany.supabase.co');
  });

  it('never leaks secret values in validation error messages', () => {
    const config = {
      DATABASE_URL: 'not-valid-db',
      PORT: -10,
    };

    try {
      validateEnvironment(config);
      expect.unreachable('Should have thrown');
    } catch (err) {
      const message = (err as Error).message;
      expect(message).not.toContain('not-valid-db');
      expect(message).toContain('Property "DATABASE_URL"');
      expect(message).toContain('Property "PORT"');
    }
  });

  it('formatValidationErrors formats errors cleanly', () => {
    const result = formatValidationErrors([
      {
        property: 'PORT',
        constraints: { min: 'PORT must be at least 1' },
      } as any,
    ]);
    expect(result).toBe('Property "PORT": PORT must be at least 1');
  });
});
