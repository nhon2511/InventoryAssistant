import {
  Injectable,
  NotFoundException,
  UnprocessableEntityException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import type {
  InventoryStockQueryDto,
  ReceiveInventoryDto,
  ShipInventoryDto,
} from './dto/inventory-movement.dto.js';

@Injectable()
export class InventoryService {
  constructor(private readonly prisma: PrismaService) {}

  async receive(dto: ReceiveInventoryDto) {
    const product = await this.prisma.product.findUnique({
      where: { id: dto.productId },
    });
    if (!product) {
      throw new NotFoundException(`Product not found: ${dto.productId}`);
    }

    const location = await this.prisma.location.findUnique({
      where: { id: dto.locationId },
    });
    if (!location) {
      throw new NotFoundException(`Location not found: ${dto.locationId}`);
    }

    const existing = await this.prisma.inventoryItem.findFirst({
      where: {
        productId: dto.productId,
        locationId: dto.locationId,
        lotNumber: dto.lotNumber ?? null,
      },
    });

    if (existing) {
      return this.prisma.inventoryItem.update({
        where: { id: existing.id },
        data: {
          quantityOnHand: { increment: dto.quantity },
          expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : existing.expiryDate,
        },
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
      });
    }

    return this.prisma.inventoryItem.create({
      data: {
        productId: dto.productId,
        locationId: dto.locationId,
        quantityOnHand: dto.quantity,
        quantityReserved: 0,
        lotNumber: dto.lotNumber ?? null,
        expiryDate: dto.expiryDate ? new Date(dto.expiryDate) : null,
      },
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
    });
  }

  async ship(dto: ShipInventoryDto) {
    return this.prisma.$transaction(async (tx) => {
      const item = await tx.inventoryItem.findFirst({
        where: {
          productId: dto.productId,
          locationId: dto.locationId,
          ...(dto.lotNumber !== undefined ? { lotNumber: dto.lotNumber ?? null } : {}),
        },
      });

      if (!item) {
        throw new NotFoundException('Inventory item not found for product at specified location');
      }

      const available = item.quantityOnHand - item.quantityReserved;
      if (available < dto.quantity) {
        throw new UnprocessableEntityException(
          `Insufficient available inventory: available ${available}, requested ${dto.quantity}`,
        );
      }

      return tx.inventoryItem.update({
        where: { id: item.id },
        data: {
          quantityOnHand: { decrement: dto.quantity },
        },
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
      });
    });
  }

  async getStock(query: InventoryStockQueryDto) {
    const where: Prisma.InventoryItemWhereInput = {};
    if (query.productId) {
      where.productId = query.productId;
    }
    if (query.locationId) {
      where.locationId = query.locationId;
    }

    return this.prisma.inventoryItem.findMany({
      where,
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
      orderBy: { updatedAt: 'desc' },
    });
  }
}
