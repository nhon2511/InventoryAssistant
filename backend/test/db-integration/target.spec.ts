import { describe, expect, it } from 'vitest';
import { assertDbTestTarget } from './target.js';

const ref = 'abcdefghijklmnopqrst';
const dev = 'zyxwvutsrqponmlkjihg';
const env: NodeJS.ProcessEnv = {
  DATABASE_TEST_URL: `postgresql://postgres:placeholder@db.${ref}.supabase.co:5432/postgres?sslmode=require&sslaccept=strict`,
  DATABASE_TEST_BACKEND_URL: `postgresql://wms_backend:placeholder@db.${ref}.supabase.co:5432/postgres?sslmode=require&sslaccept=strict`,
  DATABASE_TEST_PROJECT_REF: ref,
  DATABASE_DEV_PROJECT_REF: dev,
  DATABASE_TEST_ALLOWED_REFS: ref,
  DATABASE_TEST_ACTOR_ID: '00000000-0000-4000-8000-000000000001',
  DATABASE_TEST_APPROVED: 'YES',
};

describe('DB integration target guard (pure, no connection)', () => {
  it('requires a separate direct PG17 test project declaration', () => {
    expect(assertDbTestTarget(env).projectRef).toBe(ref);
  });
  it('rejects missing URL, fallback, dev ref and absent approval', () => {
    for (const changes of [
      { DATABASE_TEST_URL: undefined },
      { DATABASE_TEST_PROJECT_REF: dev },
      { DATABASE_TEST_ALLOWED_REFS: dev },
      { DATABASE_TEST_APPROVED: undefined },
      { DATABASE_TEST_ACTOR_ID: undefined },
    ]) expect(() => assertDbTestTarget({ ...env, ...changes })).toThrow();
  });
  it('rejects wrong host, port, database, TLS and role without echoing URL', () => {
    for (const url of [
      `postgresql://postgres:placeholder@db.${dev}.supabase.co:5432/postgres?sslmode=require&sslaccept=strict`,
      `postgresql://postgres:placeholder@db.${ref}.supabase.co:6543/postgres?sslmode=require&sslaccept=strict`,
      `postgresql://postgres:placeholder@db.${ref}.supabase.co:5432/other?sslmode=require&sslaccept=strict`,
      `postgresql://postgres:placeholder@db.${ref}.supabase.co:5432/postgres?sslmode=require`,
      `postgresql://service_role:placeholder@db.${ref}.supabase.co:5432/postgres?sslmode=require&sslaccept=strict`,
    ]) {
      try { assertDbTestTarget({ ...env, DATABASE_TEST_URL: url }); throw new Error('expected rejection'); }
      catch (error) {
        expect((error as Error).message).not.toContain('placeholder');
        expect((error as Error).message).not.toBe('expected rejection');
      }
    }
  });
});
