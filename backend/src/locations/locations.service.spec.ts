import { ConflictException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { LocationsService } from './locations.service.js';

function makePrisma() {
  return {
    location: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
  };
}

const SAMPLE_LOCATION = {
  id: '660e8400-e29b-41d4-a716-446655440001',
  zoneCode: 'Z-A',
  aisleCode: 'A-01',
  rackCode: 'R-01',
  binCode: 'B-01',
  locationBarcode: 'LOC-ZA-A01-R01-B01',
  maxCapacityKg: null,
  createdAt: new Date('2026-01-01'),
};

describe('LocationsService', () => {
  let service: LocationsService;
  let prisma: ReturnType<typeof makePrisma>;

  beforeEach(() => {
    prisma = makePrisma();
    service = new LocationsService(prisma as never);
  });

  describe('findAll', () => {
    it('returns all locations ordered by zoneCode, aisleCode, rackCode, binCode asc', async () => {
      prisma.location.findMany.mockResolvedValue([SAMPLE_LOCATION]);
      const result = await service.findAll();
      expect(result).toEqual([SAMPLE_LOCATION]);
      expect(prisma.location.findMany).toHaveBeenCalledWith({
        orderBy: [
          { zoneCode: 'asc' },
          { aisleCode: 'asc' },
          { rackCode: 'asc' },
          { binCode: 'asc' },
        ],
      });
    });
  });

  describe('findById', () => {
    it('finds by UUID', async () => {
      prisma.location.findUnique.mockResolvedValue(SAMPLE_LOCATION);
      const result = await service.findById(SAMPLE_LOCATION.id);
      expect(result).toEqual(SAMPLE_LOCATION);
      expect(prisma.location.findUnique).toHaveBeenCalledWith({
        where: { id: SAMPLE_LOCATION.id },
      });
    });

    it('finds by locationBarcode', async () => {
      prisma.location.findUnique.mockResolvedValue(SAMPLE_LOCATION);
      const result = await service.findById('LOC-ZA-A01-R01-B01');
      expect(result).toEqual(SAMPLE_LOCATION);
      expect(prisma.location.findUnique).toHaveBeenCalledWith({
        where: { locationBarcode: 'LOC-ZA-A01-R01-B01' },
      });
    });

    it('throws NotFoundException when not found', async () => {
      prisma.location.findUnique.mockResolvedValue(null);
      await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('creates a location successfully', async () => {
      prisma.location.create.mockResolvedValue(SAMPLE_LOCATION);
      const result = await service.create({
        zoneCode: 'Z-A',
        aisleCode: 'A-01',
        rackCode: 'R-01',
        binCode: 'B-01',
        locationBarcode: 'LOC-ZA-A01-R01-B01',
      });
      expect(result).toEqual(SAMPLE_LOCATION);
      expect(prisma.location.create).toHaveBeenCalledWith({
        data: {
          zoneCode: 'Z-A',
          aisleCode: 'A-01',
          rackCode: 'R-01',
          binCode: 'B-01',
          locationBarcode: 'LOC-ZA-A01-R01-B01',
          maxCapacityKg: null,
        },
      });
    });

    it('creates a location with maxCapacityKg', async () => {
      const locationWithCapacity = { ...SAMPLE_LOCATION, maxCapacityKg: 500 };
      prisma.location.create.mockResolvedValue(locationWithCapacity);
      const result = await service.create({
        zoneCode: 'Z-A',
        aisleCode: 'A-01',
        rackCode: 'R-01',
        binCode: 'B-01',
        locationBarcode: 'LOC-ZA-A01-R01-B01',
        maxCapacityKg: 500,
      });
      expect(result).toEqual(locationWithCapacity);
      expect(prisma.location.create).toHaveBeenCalledWith({
        data: {
          zoneCode: 'Z-A',
          aisleCode: 'A-01',
          rackCode: 'R-01',
          binCode: 'B-01',
          locationBarcode: 'LOC-ZA-A01-R01-B01',
          maxCapacityKg: 500,
        },
      });
    });

    it('throws ConflictException on duplicate locationBarcode', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Unique', {
        code: 'P2002',
        meta: { target: ['location_barcode'] },
        clientVersion: '6.0.0',
      });
      prisma.location.create.mockRejectedValue(error);
      await expect(
        service.create({
          zoneCode: 'Z-A',
          aisleCode: 'A-01',
          rackCode: 'R-01',
          binCode: 'B-01',
          locationBarcode: 'LOC-DUP',
        }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('update', () => {
    it('updates only provided fields', async () => {
      prisma.location.update.mockResolvedValue({ ...SAMPLE_LOCATION, rackCode: 'R-02' });
      const result = await service.update(SAMPLE_LOCATION.id, { rackCode: 'R-02' });
      expect(result.rackCode).toBe('R-02');
      expect(prisma.location.update).toHaveBeenCalledWith({
        where: { id: SAMPLE_LOCATION.id },
        data: { rackCode: 'R-02' },
      });
    });

    it('returns existing location when no fields provided', async () => {
      prisma.location.findUnique.mockResolvedValue(SAMPLE_LOCATION);
      const result = await service.update(SAMPLE_LOCATION.id, {});
      expect(result).toEqual(SAMPLE_LOCATION);
      expect(prisma.location.update).not.toHaveBeenCalled();
    });

    it('throws NotFoundException on P2025', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Not found', {
        code: 'P2025',
        meta: {},
        clientVersion: '6.0.0',
      });
      prisma.location.update.mockRejectedValue(error);
      await expect(
        service.update('nonexistent', { zoneCode: 'Z-X' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException on duplicate locationBarcode', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Unique', {
        code: 'P2002',
        meta: { target: ['location_barcode'] },
        clientVersion: '6.0.0',
      });
      prisma.location.update.mockRejectedValue(error);
      await expect(
        service.update(SAMPLE_LOCATION.id, { locationBarcode: 'DUP' }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('remove', () => {
    it('deletes when no references exist', async () => {
      prisma.location.findUnique.mockResolvedValue({
        ...SAMPLE_LOCATION,
        _count: { inventoryItems: 0, orderItems: 0 },
      });
      prisma.location.delete.mockResolvedValue(SAMPLE_LOCATION);
      await service.remove(SAMPLE_LOCATION.id);
      expect(prisma.location.delete).toHaveBeenCalledWith({
        where: { id: SAMPLE_LOCATION.id },
      });
    });

    it('throws NotFoundException when location missing', async () => {
      prisma.location.findUnique.mockResolvedValue(null);
      await expect(service.remove('nonexistent')).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when inventory items reference location', async () => {
      prisma.location.findUnique.mockResolvedValue({
        ...SAMPLE_LOCATION,
        _count: { inventoryItems: 2, orderItems: 0 },
      });
      await expect(service.remove(SAMPLE_LOCATION.id)).rejects.toThrow(ConflictException);
      expect(prisma.location.delete).not.toHaveBeenCalled();
    });

    it('throws ConflictException when order items reference location', async () => {
      prisma.location.findUnique.mockResolvedValue({
        ...SAMPLE_LOCATION,
        _count: { inventoryItems: 0, orderItems: 4 },
      });
      await expect(service.remove(SAMPLE_LOCATION.id)).rejects.toThrow(ConflictException);
      expect(prisma.location.delete).not.toHaveBeenCalled();
    });
  });
});
