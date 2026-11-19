import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { describe, expect, it } from 'vitest';
import { PrismaModule } from '../prisma/prisma.module.js';
import { ProductsController } from './products.controller.js';
import { ProductsModule } from './products.module.js';
import { ProductsService } from './products.service.js';

describe('ProductsModule', () => {
  it('compiles and provides ProductsController and ProductsService', async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          ignoreEnvFile: true,
          load: [() => ({
            SUPABASE_URL: 'https://test-project.supabase.co/',
            NODE_ENV: 'test',
          })],
        }),
        PrismaModule,
        ProductsModule,
      ],
    }).compile();

    expect(moduleRef.get(ProductsController)).toBeDefined();
    expect(moduleRef.get(ProductsService)).toBeDefined();
  });
});
