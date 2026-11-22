import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import { OrderTypeEnum, type OrderQueryDto } from './dto/order-query.dto.js';
import type { CreateOrderDraftDto } from './dto/create-order-draft.dto.js';

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

  async createDraft(dto: CreateOrderDraftDto, actorId: string | null) {
    return this.prisma.$transaction(async (tx) => {
      // 1. Verify that all products exist
      const productIds = [...new Set(dto.items.map((i) => i.productId))];
      const products = await tx.product.findMany({
        where: { id: { in: productIds } },
        select: { id: true },
      });
      const existingProductIds = new Set(products.map((p) => p.id));
      for (const pid of productIds) {
        if (!existingProductIds.has(pid)) {
          throw new NotFoundException(`Product not found: ${pid}`);
        }
      }

      // 2. Verify that all specified locations exist
      const locationIds = [
        ...new Set(
          dto.items
            .map((i) => i.locationId)
            .filter((lid): lid is string => Boolean(lid)),
        ),
      ];
      if (locationIds.length > 0) {
        const locations = await tx.location.findMany({
          where: { id: { in: locationIds } },
          select: { id: true },
        });
        const existingLocationIds = new Set(locations.map((l) => l.id));
        for (const lid of locationIds) {
          if (!existingLocationIds.has(lid)) {
            throw new NotFoundException(`Location not found: ${lid}`);
          }
        }
      }

      // 3. Generate standard orderCode: INB-YYYYMM-XXXX or OUTB-YYYYMM-XXXX
      const now = new Date();
      const prefix = `${dto.type === OrderTypeEnum.INBOUND ? 'INB' : 'OUTB'}-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
      const lastOrder = await tx.warehouseOrder.findFirst({
        where: { orderCode: { startsWith: prefix } },
        orderBy: { orderCode: 'desc' },
        select: { orderCode: true },
      });

      let nextSeq = 1;
      if (lastOrder) {
        const parts = lastOrder.orderCode.split('-');
        const lastSeq = parseInt(parts[parts.length - 1], 10);
        if (!isNaN(lastSeq)) {
          nextSeq = lastSeq + 1;
        }
      }
      const orderCode = `${prefix}-${String(nextSeq).padStart(4, '0')}`;

      // 4. Create the draft order and its line items atomically
      return tx.warehouseOrder.create({
        data: {
          orderCode,
          type: dto.type,
          status: 'DRAFT',
          createdBy: actorId,
          note: dto.note ?? null,
          items: {
            create: dto.items.map((item) => ({
              productId: item.productId,
              locationId: item.locationId ?? null,
              expectedQuantity: item.expectedQuantity,
              actualQuantity: 0,
              lotNumber: item.lotNumber ?? null,
              expiryDate: item.expiryDate ? new Date(item.expiryDate) : null,
            })),
          },
        },
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
    });
  }

  async reviewOrder(id: string, approve: boolean, actorId: string) {
    const where = UUID_RE.test(id) ? { id } : { orderCode: id };
    const order = await this.prisma.warehouseOrder.findUnique({ where });

    if (!order) {
      throw new NotFoundException(`Order not found: ${id}`);
    }

    if (order.status !== 'DRAFT') {
      throw new ConflictException(
        `Order status is ${order.status}. Only DRAFT orders can be reviewed.`,
      );
    }

    const nextStatus = approve ? 'CONFIRMED' : 'CANCELLED';

    const updateResult = await this.prisma.warehouseOrder.updateMany({
      where: { id: order.id, status: 'DRAFT' },
      data: {
        status: nextStatus,
        approvedBy: approve ? actorId : null,
      },
    });

    if (updateResult.count === 0) {
      throw new ConflictException(
        'Order cannot be reviewed because it is no longer in DRAFT status.',
      );
    }

    return this.findById(order.id);
  }
}
