import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service.js';
import type { CreateLocationDto, UpdateLocationDto } from './dto/location.dto.js';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

@Injectable()
export class LocationsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.location.findMany({
      orderBy: [
        { zoneCode: 'asc' },
        { aisleCode: 'asc' },
        { rackCode: 'asc' },
        { binCode: 'asc' },
      ],
    });
  }

  async findById(id: string) {
    const where = UUID_RE.test(id) ? { id } : { locationBarcode: id };
    const location = await this.prisma.location.findUnique({ where });
    if (!location) {
      throw new NotFoundException(`Location not found: ${id}`);
    }
    return location;
  }

  async create(dto: CreateLocationDto) {
    try {
      return await this.prisma.location.create({
        data: {
          zoneCode: dto.zoneCode,
          aisleCode: dto.aisleCode,
          rackCode: dto.rackCode,
          binCode: dto.binCode,
          locationBarcode: dto.locationBarcode,
          maxCapacityKg: dto.maxCapacityKg !== undefined ? dto.maxCapacityKg : null,
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'Location with duplicate locationBarcode already exists',
        );
      }
      throw error;
    }
  }

  async update(id: string, dto: UpdateLocationDto) {
    const data: Prisma.LocationUpdateInput = {};
    if (dto.zoneCode !== undefined) data.zoneCode = dto.zoneCode;
    if (dto.aisleCode !== undefined) data.aisleCode = dto.aisleCode;
    if (dto.rackCode !== undefined) data.rackCode = dto.rackCode;
    if (dto.binCode !== undefined) data.binCode = dto.binCode;
    if (dto.locationBarcode !== undefined) data.locationBarcode = dto.locationBarcode;
    if (dto.maxCapacityKg !== undefined) data.maxCapacityKg = dto.maxCapacityKg;

    if (Object.keys(data).length === 0) {
      return this.findById(id);
    }

    try {
      return await this.prisma.location.update({
        where: { id },
        data,
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2025'
      ) {
        throw new NotFoundException(`Location not found: ${id}`);
      }
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        throw new ConflictException(
          'Location with duplicate locationBarcode already exists',
        );
      }
      throw error;
    }
  }

  async remove(id: string) {
    const location = await this.prisma.location.findUnique({
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

    if (!location) {
      throw new NotFoundException(`Location not found: ${id}`);
    }

    if (location._count.inventoryItems > 0) {
      throw new ConflictException(
        `Cannot delete location: ${location._count.inventoryItems} inventory item(s) still reference it`,
      );
    }

    if (location._count.orderItems > 0) {
      throw new ConflictException(
        `Cannot delete location: ${location._count.orderItems} order item(s) still reference it`,
      );
    }

    await this.prisma.location.delete({ where: { id } });
  }
}
