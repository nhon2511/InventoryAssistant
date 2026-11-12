import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { PrismaService } from '../prisma/prisma.service.js';

export interface HealthResponse {
  status: 'ok' | 'degraded';
  timestamp: string;
  uptime: number;
  version: string;
  environment: string;
  services: {
    database: 'connected' | 'disconnected' | 'not_verified';
  };
}

export interface LivenessResponse {
  status: 'ok';
  timestamp: string;
  uptime: number;
}

export interface ReadinessResponse {
  status: 'ready' | 'not_ready';
  timestamp: string;
  database: 'connected' | 'disconnected';
}

@ApiTags('Health')
@Controller('health')
export class HealthController {
  constructor(
    private readonly prisma: PrismaService,
    private readonly configService: ConfigService,
  ) {}

  @Get()
  @ApiOperation({ summary: 'System health overview' })
  @ApiResponse({
    status: 200,
    description: 'Service health information',
    schema: {
      example: {
        success: true,
        statusCode: 200,
        data: {
          status: 'ok',
          timestamp: '2026-11-12T19:30:00.000Z',
          uptime: 12.34,
          version: '1.0.0',
          environment: 'development',
          services: {
            database: 'connected',
          },
        },
        timestamp: '2026-11-12T19:30:00.000Z',
      },
    },
  })
  async check(): Promise<HealthResponse> {
    const isDbHealthy = await this.prisma.checkHealth();
    const env = this.configService.get<string>('NODE_ENV') ?? 'development';

    return {
      status: isDbHealthy ? 'ok' : 'degraded',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      version: '1.0.0',
      environment: env,
      services: {
        database: isDbHealthy ? 'connected' : 'disconnected',
      },
    };
  }

  @Get('liveness')
  @ApiOperation({ summary: 'Process liveness check' })
  @ApiResponse({
    status: 200,
    description: 'Process is alive and responding',
  })
  checkLiveness(): LivenessResponse {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
    };
  }

  @Get('readiness')
  @ApiOperation({ summary: 'Service readiness check' })
  @ApiResponse({
    status: 200,
    description: 'Service database readiness check',
  })
  async checkReadiness(): Promise<ReadinessResponse> {
    const isDbHealthy = await this.prisma.checkHealth();

    return {
      status: isDbHealthy ? 'ready' : 'not_ready',
      timestamp: new Date().toISOString(),
      database: isDbHealthy ? 'connected' : 'disconnected',
    };
  }
}
