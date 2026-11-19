import { describe, it, expect } from 'vitest';
import { Test } from '@nestjs/testing';
import { ConfigModule } from '@nestjs/config';
import { OrdersModule } from './orders.module.js';
import { OrdersController } from './orders.controller.js';
import { OrderConfirmationService } from '../inventory-contract/order-confirmation.service.js';
import { PrismaModule } from '../prisma/prisma.module.js';

describe('OrdersModule', () => {
  it('compiles and provides OrdersController and OrderConfirmationService', async () => {
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
        OrdersModule,
      ],
    }).compile();

    expect(moduleRef.get(OrdersController)).toBeDefined();
    expect(moduleRef.get(OrderConfirmationService)).toBeDefined();
  });
});
