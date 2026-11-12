import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PrismaService } from './prisma.service.js';

describe('PrismaService', () => {
  let service: PrismaService;

  beforeEach(() => {
    service = new PrismaService();
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('checkHealth should return true when query succeeds', async () => {
    vi.spyOn(service, '$queryRaw').mockResolvedValue([{ '?column?': 1 }]);
    const healthy = await service.checkHealth();
    expect(healthy).toBe(true);
  });

  it('checkHealth should return false when query fails', async () => {
    vi.spyOn(service, '$queryRaw').mockRejectedValue(new Error('Connection error'));
    const healthy = await service.checkHealth();
    expect(healthy).toBe(false);
  });
});
