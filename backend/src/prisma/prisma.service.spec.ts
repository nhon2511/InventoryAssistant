import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PrismaService } from './prisma.service.js';

describe('PrismaService', () => {
  let service: PrismaService;

  beforeEach(() => {
    service = new PrismaService();
  });

  it('should be defined with initial disconnected status', () => {
    expect(service).toBeDefined();
    expect(service.isConnectionEstablished).toBe(false);
  });

  it('sanitizeError should mask sensitive connection credentials', () => {
    const rawError = new Error(
      'Failed connecting to postgresql://postgres.abcdef:SuperSecret123@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres',
    );
    const sanitized = service.sanitizeError(rawError);
    expect(sanitized).not.toContain('SuperSecret123');
    expect(sanitized).toContain('postgresql://***:***@aws-0-ap-southeast-1');
  });

  it('sanitizeError should mask sensitive query parameter tokens and keys', () => {
    const rawError = new Error(
      'Request to postgresql://dbuser:mypassword@supabase.co:5432/db?apikey=sbp_secretkey123&token=jwt_xyz456 failed',
    );
    const sanitized = service.sanitizeError(rawError);
    expect(sanitized).not.toContain('mypassword');
    expect(sanitized).not.toContain('sbp_secretkey123');
    expect(sanitized).not.toContain('jwt_xyz456');
    expect(sanitized).toContain('apikey=***');
    expect(sanitized).toContain('token=***');
  });

  it('sanitizeError should return plain string when no uri present', () => {
    const rawError = new Error('Socket closed unexpectedly');
    expect(service.sanitizeError(rawError)).toBe('Socket closed unexpectedly');
  });

  it('onModuleInit should skip connection if PRISMA_SKIP_CONNECT=true', async () => {
    const connectSpy = vi.spyOn(service, '$connect').mockResolvedValue();
    process.env.PRISMA_SKIP_CONNECT = 'true';

    await service.onModuleInit();

    expect(connectSpy).not.toHaveBeenCalled();
    expect(service.isConnectionEstablished).toBe(false);

    delete process.env.PRISMA_SKIP_CONNECT;
  });

  it('PRISMA_SKIP_CONNECT should not allow backend to report ready without successful query', async () => {
    process.env.PRISMA_SKIP_CONNECT = 'true';
    await service.onModuleInit();

    expect(service.isConnectionEstablished).toBe(false);

    vi.spyOn(service, '$queryRaw').mockRejectedValue(new Error('Connection refused'));
    const isHealthy = await service.checkHealth();

    expect(isHealthy).toBe(false);
    expect(service.isConnectionEstablished).toBe(false);

    delete process.env.PRISMA_SKIP_CONNECT;
  });

  it('onModuleInit should set isConnectionEstablished=true on success', async () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    delete process.env.PRISMA_SKIP_CONNECT;

    const connectSpy = vi.spyOn(service, '$connect').mockResolvedValue();

    await service.onModuleInit();

    expect(connectSpy).toHaveBeenCalledTimes(1);
    expect(service.isConnectionEstablished).toBe(true);

    process.env.NODE_ENV = originalEnv;
  });

  it('onModuleInit should catch connection failure and defer gracefully', async () => {
    const originalEnv = process.env.NODE_ENV;
    process.env.NODE_ENV = 'development';
    delete process.env.PRISMA_SKIP_CONNECT;

    vi.spyOn(service, '$connect').mockRejectedValue(
      new Error('Connection timed out'),
    );

    await service.onModuleInit();

    expect(service.isConnectionEstablished).toBe(false);

    process.env.NODE_ENV = originalEnv;
  });

  it('onModuleDestroy should call $disconnect and reset isConnected', async () => {
    const disconnectSpy = vi.spyOn(service, '$disconnect').mockResolvedValue();

    await service.onModuleDestroy();

    expect(disconnectSpy).toHaveBeenCalledTimes(1);
    expect(service.isConnectionEstablished).toBe(false);
  });

  it('checkHealth should return true when query succeeds', async () => {
    vi.spyOn(service, '$queryRaw').mockResolvedValue([{ '?column?': 1 }]);
    const healthy = await service.checkHealth();
    expect(healthy).toBe(true);
    expect(service.isConnectionEstablished).toBe(true);
  });

  it('checkHealth should return false when query fails', async () => {
    vi.spyOn(service, '$queryRaw').mockRejectedValue(new Error('Connection error'));
    const healthy = await service.checkHealth();
    expect(healthy).toBe(false);
    expect(service.isConnectionEstablished).toBe(false);
  });
});
