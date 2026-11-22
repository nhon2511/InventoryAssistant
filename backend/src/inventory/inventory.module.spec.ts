import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { describe, expect, it } from 'vitest';
import { PrismaModule } from '../prisma/prisma.module.js';
import { InventoryController } from './inventory.controller.js';
import { InventoryModule } from './inventory.module.js';
import { InventoryService } from './inventory.service.js';

describe('InventoryModule', () => {
  it('compiles and provides InventoryController and InventoryService', async () => {
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
        InventoryModule,
      ],
    }).compile();

    expect(moduleRef.get(InventoryController)).toBeDefined();
    expect(moduleRef.get(InventoryService)).toBeDefined();
  });
});
