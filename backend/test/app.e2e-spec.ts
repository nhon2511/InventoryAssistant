import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { AllExceptionsFilter } from '../src/common/filters/http-exception.filter.js';
import { TransformInterceptor } from '../src/common/interceptors/transform.interceptor.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { AppModule } from './../src/app.module.js';

describe('Smart WMS Backend (e2e)', () => {
  let app: INestApplication;
  let mockPrismaService: {
    $connect: ReturnType<typeof vi.fn>;
    $disconnect: ReturnType<typeof vi.fn>;
    checkHealth: ReturnType<typeof vi.fn>;
  };

  beforeEach(async () => {
    mockPrismaService = {
      $connect: vi.fn(),
      $disconnect: vi.fn(),
      checkHealth: vi.fn().mockResolvedValue(true),
    };

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
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
