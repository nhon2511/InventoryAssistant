import { ConfigModule, ConfigService } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import { describe, expect, it, vi } from 'vitest';
import { PrismaService } from './prisma/prisma.service.js';
import { PrismaModule } from './prisma/prisma.module.js';
import { HealthModule } from './health/health.module.js';
import { OrdersModule } from './orders/orders.module.js';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';

// AppModule uses ConfigModule.forRoot with validate, which runs at decorator
// evaluation time — before process.env can be set in beforeEach.  Instead we
// replicate the module structure with explicit config to verify wiring.
describe('AppModule', () => {
  it('should compile AppModule with mocked PrismaService without connecting to database', async () => {
    const mockPrismaService = {
      $connect: vi.fn(),
      $disconnect: vi.fn(),
      $transaction: vi.fn(),
      $queryRaw: vi.fn(),
      checkHealth: vi.fn().mockResolvedValue(true),
      isConnectionEstablished: true,
      onModuleInit: vi.fn(),
      onModuleDestroy: vi.fn(),
      sanitizeError: vi.fn((e: unknown) => String(e)),
      inventoryItem: { updateMany: vi.fn() },
      stockLedger: { create: vi.fn() },
      idempotencyKey: { updateMany: vi.fn() },
      warehouseOrder: { updateMany: vi.fn() },
    };

    const moduleRef: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({
            DATABASE_URL: 'postgresql://user:pass@localhost:5432/test',
            SUPABASE_URL: 'https://test-project.supabase.co/',
            NODE_ENV: 'test',
            API_PREFIX: '/api/v1',
          })],
        }),
        PrismaModule,
        HealthModule,
        OrdersModule,
      ],
      controllers: [AppController],
      providers: [AppService],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrismaService)
      .compile();

    expect(moduleRef).toBeDefined();

    const configService = moduleRef.get<ConfigService>(ConfigService);
    expect(configService).toBeDefined();
    expect(configService.get('API_PREFIX')).toBe('/api/v1');
  });
});
