import { INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

export function setupSwagger(app: INestApplication): void {
  const config = new DocumentBuilder()
    .setTitle('Smart WMS Backend API')
    .setDescription(
      'Warehouse Inventory Management REST API (NestJS + Prisma + Supabase)',
    )
    .setVersion('1.0.0')
    .addBearerAuth(
      {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        name: 'Authorization',
        description: 'Enter Supabase Access Token (JWT)',
        in: 'header',
      },
      'JWT-auth',
    )
    .addTag('Health', 'Health and system status check endpoints')
    .addTag('Auth', 'Authentication and profile operations')
    .addTag('Inventory', 'Products, locations, and inventory items')
    .addTag('Inbound', 'Inbound receiving orders and workflows')
    .addTag('Outbound', 'Outbound picking orders and workflows')
    .addTag('Reports', 'Warehouse reports and analytics')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  SwaggerModule.setup('docs', app, document, {
    customSiteTitle: 'Smart WMS API Docs',
    swaggerOptions: {
      persistAuthorization: true,
    },
  });
}
