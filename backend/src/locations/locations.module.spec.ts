import { ConfigModule } from '@nestjs/config';
import { Test } from '@nestjs/testing';
import { describe, expect, it } from 'vitest';
import { PrismaModule } from '../prisma/prisma.module.js';
import { LocationsController } from './locations.controller.js';
import { LocationsModule } from './locations.module.js';
import { LocationsService } from './locations.service.js';

describe('LocationsModule', () => {
  it('compiles and provides LocationsController and LocationsService', async () => {
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
        LocationsModule,
      ],
    }).compile();

    expect(moduleRef.get(LocationsController)).toBeDefined();
    expect(moduleRef.get(LocationsService)).toBeDefined();
  });
});
