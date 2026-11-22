import { INestApplication, Module, ValidationPipe } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AppController } from '../src/app.controller.js';
import { AppService } from '../src/app.service.js';
import { AllExceptionsFilter } from '../src/common/filters/http-exception.filter.js';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor.js';
import { HealthModule } from '../src/health/health.module.js';
import { LocationsModule } from '../src/locations/locations.module.js';
import { OrdersModule } from '../src/orders/orders.module.js';
import { ProductsModule } from '../src/products/products.module.js';
import { PrismaModule } from '../src/prisma/prisma.module.js';
import { PrismaService } from '../src/prisma/prisma.service.js';

// Build a test-safe module that mirrors AppModule without decorator-time
// ConfigModule.forRoot validation (which runs before env vars are set).
@Module({
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
    LocationsModule,
    OrdersModule,
    ProductsModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
class TestAppModule {}

describe('Smart WMS Backend (e2e)', () => {
  let app: INestApplication;
  let mockPrismaService: {
    $connect: ReturnType<typeof vi.fn>;
    $disconnect: ReturnType<typeof vi.fn>;
    $transaction: ReturnType<typeof vi.fn>;
    $queryRaw: ReturnType<typeof vi.fn>;
    checkHealth: ReturnType<typeof vi.fn>;
    isConnectionEstablished: boolean;
    onModuleInit: ReturnType<typeof vi.fn>;
    onModuleDestroy: ReturnType<typeof vi.fn>;
    sanitizeError: ReturnType<typeof vi.fn>;
    inventoryItem: { updateMany: ReturnType<typeof vi.fn> };
    stockLedger: { create: ReturnType<typeof vi.fn> };
    idempotencyKey: { updateMany: ReturnType<typeof vi.fn> };
    warehouseOrder: {
      updateMany: ReturnType<typeof vi.fn>;
      findMany: ReturnType<typeof vi.fn>;
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
    };
    location: {
      findMany: ReturnType<typeof vi.fn>;
      findUnique: ReturnType<typeof vi.fn>;
      create: ReturnType<typeof vi.fn>;
      update: ReturnType<typeof vi.fn>;
      delete: ReturnType<typeof vi.fn>;
    };
  };

  beforeEach(async () => {
    mockPrismaService = {
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
      warehouseOrder: {
        updateMany: vi.fn(),
        findMany: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
      },
      location: {
        findMany: vi.fn(),
        findUnique: vi.fn(),
        create: vi.fn(),
        update: vi.fn(),
        delete: vi.fn(),
      },
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [TestAppModule],
    })
      .overrideProvider(PrismaService)
      .useValue(mockPrismaService)
      .compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: true,
      }),
    );
    app.useGlobalFilters(new AllExceptionsFilter());
    app.useGlobalInterceptors(new TransformInterceptor());

    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('GET /api/v1/health should return 200 and structured health envelope when DB is connected', async () => {
    mockPrismaService.checkHealth.mockResolvedValue(true);

    const response = await request(app.getHttpServer())
      .get('/api/v1/health')
      .expect(200);

    expect(response.body).toHaveProperty('success', true);
    expect(response.body).toHaveProperty('statusCode', 200);
    expect(response.body).toHaveProperty('data');
    expect(response.body.data).toHaveProperty('status', 'ok');
    expect(response.body.data).toHaveProperty('version', '1.0.0');
    expect(response.body.data.services).toHaveProperty('database', 'connected');
    expect(response.body).toHaveProperty('timestamp');
  });

  it('POST /api/v1/orders/:id/confirm requires authentication', async () => {
    // Without a Bearer token, the guard should reject with 401.
    await request(app.getHttpServer())
      .post('/api/v1/orders/00000000-0000-4000-8000-000000000002/confirm')
      .send({ type: 'OUTBOUND', idempotencyKey: 'e2e-test-key' })
      .expect(401);
  });

  it('GET /api/v1/health/liveness should return 200 and liveness envelope', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/health/liveness')
      .expect(200);

    expect(response.body).toHaveProperty('success', true);
    expect(response.body).toHaveProperty('statusCode', 200);
    expect(response.body.data).toHaveProperty('status', 'ok');
    expect(response.body.data).toHaveProperty('uptime');
    expect(response.body.data.uptime).toBeGreaterThanOrEqual(0);
  });

  it('GET /api/v1/health/readiness should return 200 when database is healthy', async () => {
    mockPrismaService.checkHealth.mockResolvedValue(true);

    const response = await request(app.getHttpServer())
      .get('/api/v1/health/readiness')
      .expect(200);

    expect(response.body).toHaveProperty('success', true);
    expect(response.body).toHaveProperty('statusCode', 200);
    expect(response.body.data).toHaveProperty('status', 'ready');
    expect(response.body.data).toHaveProperty('database', 'connected');
  });

  it('GET /api/v1/health/readiness should return 503 when database is disconnected', async () => {
    mockPrismaService.checkHealth.mockResolvedValue(false);

    const response = await request(app.getHttpServer())
      .get('/api/v1/health/readiness')
      .expect(503);

    expect(response.body).toHaveProperty('success', false);
    expect(response.body).toHaveProperty('statusCode', 503);
    expect(response.body.data).toHaveProperty('status', 'not_ready');
    expect(response.body.data).toHaveProperty('database', 'disconnected');
  });

  it('GET /api/v1/products requires authentication', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/products')
      .expect(401);
  });

  it('POST /api/v1/products requires authentication', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/products')
      .send({ name: 'Test', sku: 'SKU-1', barcode: 'BC-1' })
      .expect(401);
  });

  it('GET /api/v1/locations requires authentication', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/locations')
      .expect(401);
  });

  it('POST /api/v1/locations requires authentication', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/locations')
      .send({
        zoneCode: 'Z-A',
        aisleCode: 'A-01',
        rackCode: 'R-01',
        binCode: 'B-01',
        locationBarcode: 'LOC-ZA-A01-R01-B01',
      })
      .expect(401);
  });

  it('GET /api/v1/orders requires authentication', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/orders')
      .expect(401);
  });

  it('GET /api/v1/orders/:id requires authentication', async () => {
    await request(app.getHttpServer())
      .get('/api/v1/orders/INB-202611-0001')
      .expect(401);
  });

  it('POST /api/v1/orders/draft requires authentication', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/orders/draft')
      .send({
        type: 'INBOUND',
        items: [
          {
            productId: '550e8400-e29b-41d4-a716-446655440001',
            expectedQuantity: 5,
          },
        ],
      })
      .expect(401);
  });

  it('POST /api/v1/orders/:id/review requires authentication', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/orders/INB-202611-0001/review')
      .send({ approve: true })
      .expect(401);
  });

  it('GET /api/v1/non-existent-route should return 404 with standard error filter', async () => {
    const response = await request(app.getHttpServer())
      .get('/api/v1/non-existent-route')
      .expect(404);

    expect(response.body).toHaveProperty('success', false);
    expect(response.body).toHaveProperty('statusCode', 404);
    expect(response.body).toHaveProperty('error');
    expect(response.body).toHaveProperty('path', '/api/v1/non-existent-route');
    expect(response.body).toHaveProperty('timestamp');
  });
});
