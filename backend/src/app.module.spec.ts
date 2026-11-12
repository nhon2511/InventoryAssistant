import { ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { describe, expect, it, vi } from 'vitest';
import { AppModule } from './app.module.js';
import { PrismaService } from './prisma/prisma.service.js';

describe('AppModule', () => {
  it('should compile AppModule with mocked PrismaService without connecting to database', async () => {
    const mockPrismaService = {
      $connect: vi.fn(),
      $disconnect: vi.fn(),
      checkHealth: vi.fn().mockResolvedValue(true),
    };

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrismaService)
      .compile();

    expect(moduleRef).toBeDefined();

    const configService = moduleRef.get<ConfigService>(ConfigService);
    expect(configService).toBeDefined();
    // Default API prefix check
    expect(configService.get('API_PREFIX')).toBeDefined();
  });
});
