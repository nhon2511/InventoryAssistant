import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CreateProductDto, UpdateProductDto } from './dto/product.dto.js';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class ProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.product.findMany({
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    const where = UUID_RE.test(id) ? { id } : { barcode: id };
    const product = await this.prisma.product.findUnique({ where });
    if (!product) {
      throw new NotFoundException(`Product not found: ${id}`);
    }
    return product;
  }

  async create(dto: CreateProductDto) {
    try {
      return await this.prisma.product.create({
        data: {
          name: dto.name,
          sku: dto.sku,
          barcode: dto.barcode,
          unit: dto.unit ?? 'Pcs',
          description: dto.description ?? null,
          minSafetyStock: dto.minSafetyStock ?? 0,
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const target = error.meta?.target;
        const field = Array.isArray(target) ? target.join(', ') : String(target ?? 'unknown');
        throw new ConflictException(
          `Product with duplicate ${field} already exists`,
        );
      }
      throw error;
    }
  }

  async update(id: string, dto: UpdateProductDto) {
    const data: Prisma.ProductUpdateInput = {};
    if (dto.name !== undefined) data.name = dto.name;
    if (dto.sku !== undefined) data.sku = dto.sku;
    if (dto.barcode !== undefined) data.barcode = dto.barcode;
    if (dto.unit !== undefined) data.unit = dto.unit;
    if (dto.description !== undefined) data.description = dto.description;
    if (dto.minSafetyStock !== undefined) data.minSafetyStock = dto.minSafetyStock;

    if (Object.keys(data).length === 0) {
      return this.findById(id);
    }

    try {
      return await this.prisma.product.update({
        where: { id },
        data,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException(`Product not found: ${id}`);
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const target = error.meta?.target;
        const field = Array.isArray(target) ? target.join(', ') : String(target ?? 'unknown');
        throw new ConflictException(
          `Product with duplicate ${field} already exists`,
        );
      }
      throw error;
    }
  }

  async remove(id: string) {
    const product = await this.prisma.product.findUnique({
      where: { id },
      include: {
        _count: {
          select: {
            inventoryItems: true,
            orderItems: true,
          },
        },
      },
    });

    if (!product) {
      throw new NotFoundException(`Product not found: ${id}`);
    }

    if (product._count.inventoryItems > 0) {
      throw new ConflictException(
        `Cannot delete product: ${product._count.inventoryItems} inventory item(s) still reference it`,
      );
    }

    if (product._count.orderItems > 0) {
      throw new ConflictException(
        `Cannot delete product: ${product._count.orderItems} order item(s) still reference it`,
      );
    }

    await this.prisma.product.delete({ where: { id } });
  }
}
