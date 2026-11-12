import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService
  extends PrismaClient
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(PrismaService.name);
  private isConnected = false;

  get isConnectionEstablished(): boolean {
    return this.isConnected;
  }

  sanitizeError(error: unknown): string {
    const message = error instanceof Error ? error.message : String(error);
    // Mask credentials in connection strings e.g. postgresql://user:password@host
    return message
      .replace(/(postgres(?:ql)?:\/\/)[^:\s]+:[^@\s]+@/gi, '$1***:***@')
      .replace(/((?:password|token|secret|key|apikey)=)[^&\s]+/gi, '$1***');
  }

  async onModuleInit() {
    if (
      process.env.NODE_ENV === 'test' ||
      process.env.PRISMA_SKIP_CONNECT === 'true'
    ) {
      this.logger.log('Prisma connection skipped (test/offline mode).');
      return;
    }

    try {
      await this.$connect();
      this.isConnected = true;
      this.logger.log('Prisma connected to database successfully.');
    } catch (error) {
      this.isConnected = false;
      const sanitized = this.sanitizeError(error);
      this.logger.warn(`Prisma database connection deferred: ${sanitized}`);
    }
  }

  async onModuleDestroy() {
    try {
      await this.$disconnect();
    } finally {
      this.isConnected = false;
      this.logger.log('Prisma disconnected from database.');
    }
  }

  async checkHealth(): Promise<boolean> {
    try {
      await this.$queryRaw`SELECT 1`;
      this.isConnected = true;
      return true;
    } catch {
      this.isConnected = false;
      return false;
    }
  }
}
