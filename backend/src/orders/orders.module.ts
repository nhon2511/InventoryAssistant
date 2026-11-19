import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module.js';
import { VERIFIED_PRINCIPAL_PROVIDER, type VerifiedPrincipalProvider } from '../inventory-contract/inventory-command.service.js';
import { OrderConfirmationService } from '../inventory-contract/order-confirmation.service.js';
import { PrismaOrderConfirmationAdapter } from '../inventory-contract/prisma-order-confirmation.adapter.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { OrdersController } from './orders.controller.js';

/** Token for the OrderConfirmationRunner dependency. */
export const ORDER_CONFIRMATION_RUNNER = 'ORDER_CONFIRMATION_RUNNER';

@Module({
  imports: [AuthModule],
  controllers: [OrdersController],
  providers: [
    // Prisma adapter as the OrderConfirmationRunner implementation.
    {
      provide: ORDER_CONFIRMATION_RUNNER,
      useFactory: (prisma: PrismaService) =>
        new PrismaOrderConfirmationAdapter(prisma),
      inject: [PrismaService],
    },
    // OrderConfirmationService wired with the runner and principal provider.
    // The service calls verifyAccessToken internally (defence-in-depth):
    // the Guard already verified the JWT once, but the service re-verifies
    // to enforce its own contract invariants before writing to DB.
    {
      provide: OrderConfirmationService,
      useFactory: (
        runner: PrismaOrderConfirmationAdapter,
        principals: VerifiedPrincipalProvider,
      ) => new OrderConfirmationService(runner, principals),
      inject: [ORDER_CONFIRMATION_RUNNER, VERIFIED_PRINCIPAL_PROVIDER],
    },
  ],
})
export class OrdersModule {}
