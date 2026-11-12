import { describe, expect, it } from 'vitest';
import { Environment, validateEnvironment } from './env.validation.js';

describe('validateEnvironment', () => {
  it('should validate and supply defaults for empty config', () => {
    const config = {
      DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/postgres',
    };
    const validated = validateEnvironment(config);
    expect(validated.PORT).toBe(3000);
    expect(validated.NODE_ENV).toBe(Environment.Development);
    expect(validated.API_PREFIX).toBe('/api/v1');
  });

  it('should parse custom port as number', () => {
    const config = {
      PORT: '8080',
      DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/postgres',
    };
    const validated = validateEnvironment(config);
    expect(validated.PORT).toBe(8080);
  });

  it('should throw error for invalid environment enum', () => {
    const config = {
      NODE_ENV: 'invalid_env',
      DATABASE_URL: 'postgresql://postgres:postgres@localhost:5432/postgres',
    };
    expect(() => validateEnvironment(config)).toThrow();
  });
});
