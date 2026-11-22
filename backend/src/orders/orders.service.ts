import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import type { OrderQueryDto } from './dto/order-query.dto.js';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class OrdersService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(query: OrderQueryDto) {
    const where: Prisma.WarehouseOrderWhereInput = {};

    if (query.type) {
      where.type = query.type;
    }
    if (query.status) {
      where.status = query.status;
    }
    if (query.createdBy) {
      where.createdBy = query.createdBy;
    }
    if (query.search) {
      where.OR = [
        { orderCode: { contains: query.search, mode: 'insensitive' } },
        { note: { contains: query.search, mode: 'insensitive' } },
      ];
    }

    return this.prisma.warehouseOrder.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        _count: {
          select: { items: true },
        },
      },
    });
  }

  async findById(id: string) {
    const where = UUID_RE.test(id) ? { id } : { orderCode: id };

    const order = await this.prisma.warehouseOrder.findUnique({
      where,
      include: {
        items: {
          include: {
            product: {
              select: {
                id: true,
                name: true,
                sku: true,
                barcode: true,
                unit: true,
              },
            },
            location: {
              select: {
                id: true,
                locationBarcode: true,
                zoneCode: true,
                aisleCode: true,
                rackCode: true,
                binCode: true,
              },
            },
          },
        },
      },
    });

    if (!order) {
      throw new NotFoundException(`Order not found: ${id}`);
    }

    return order;
  }
}
