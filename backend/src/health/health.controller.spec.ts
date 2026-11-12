import { ConfigService } from '@nestjs/config';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { PrismaService } from '../prisma/prisma.service.js';
import { HealthController } from './health.controller.js';

describe('HealthController', () => {
  let controller: HealthController;
  let prismaService: PrismaService;
  let configService: ConfigService;

  beforeEach(() => {
    prismaService = {
      checkHealth: vi.fn(),
    } as unknown as PrismaService;

    configService = {
      get: vi.fn().mockReturnValue('test'),
    } as unknown as ConfigService;

    controller = new HealthController(prismaService, configService);
  });

  it('should return status ok when DB is healthy', async () => {
    vi.spyOn(prismaService, 'checkHealth').mockResolvedValue(true);
    const result = await controller.check();

    expect(result.status).toBe('ok');
    expect(result.services.database).toBe('connected');
    expect(result.environment).toBe('test');
    expect(result.uptime).toBeGreaterThanOrEqual(0);
  });

  it('should return status degraded when DB is disconnected', async () => {
    vi.spyOn(prismaService, 'checkHealth').mockResolvedValue(false);
    const result = await controller.check();

    expect(result.status).toBe('degraded');
    expect(result.services.database).toBe('disconnected');
  });
});
