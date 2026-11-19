import { ConflictException, NotFoundException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { ProductsService } from './products.service.js';

function makePrisma() {
  return {
    product: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      delete: vi.fn(),
    },
  };
}

const SAMPLE_PRODUCT = {
  id: '550e8400-e29b-41d4-a716-446655440001',
  name: 'Mì Hảo Hảo',
  sku: 'SKU-001',
  barcode: '8934563118020',
  unit: 'Thùng',
  description: 'Mì ăn liền',
  minSafetyStock: 50,
  createdAt: new Date('2026-01-01'),
  updatedAt: new Date('2026-01-01'),
};

describe('ProductsService', () => {
  let service: ProductsService;
  let prisma: ReturnType<typeof makePrisma>;

  beforeEach(() => {
    prisma = makePrisma();
    service = new ProductsService(prisma as never);
  });

  describe('findAll', () => {
    it('returns all products ordered by createdAt desc', async () => {
      prisma.product.findMany.mockResolvedValue([SAMPLE_PRODUCT]);
      const result = await service.findAll();
      expect(result).toEqual([SAMPLE_PRODUCT]);
      expect(prisma.product.findMany).toHaveBeenCalledWith({
        orderBy: { createdAt: 'desc' },
      });
    });
  });

  describe('findById', () => {
    it('finds by UUID', async () => {
      prisma.product.findUnique.mockResolvedValue(SAMPLE_PRODUCT);
      const result = await service.findById(SAMPLE_PRODUCT.id);
      expect(result).toEqual(SAMPLE_PRODUCT);
      expect(prisma.product.findUnique).toHaveBeenCalledWith({
        where: { id: SAMPLE_PRODUCT.id },
      });
    });

    it('finds by barcode', async () => {
      prisma.product.findUnique.mockResolvedValue(SAMPLE_PRODUCT);
      const result = await service.findById('8934563118020');
      expect(result).toEqual(SAMPLE_PRODUCT);
      expect(prisma.product.findUnique).toHaveBeenCalledWith({
        where: { barcode: '8934563118020' },
      });
    });

    it('throws NotFoundException when not found', async () => {
      prisma.product.findUnique.mockResolvedValue(null);
      await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });

  describe('create', () => {
    it('creates a product with defaults', async () => {
      prisma.product.create.mockResolvedValue(SAMPLE_PRODUCT);
      const result = await service.create({
        name: 'Mì Hảo Hảo',
        sku: 'SKU-001',
        barcode: '8934563118020',
      });
      expect(result).toEqual(SAMPLE_PRODUCT);
      expect(prisma.product.create).toHaveBeenCalledWith({
        data: {
          name: 'Mì Hảo Hảo',
          sku: 'SKU-001',
          barcode: '8934563118020',
          unit: 'Pcs',
          description: null,
          minSafetyStock: 0,
        },
      });
    });

    it('throws ConflictException on duplicate SKU', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Unique', {
        code: 'P2002',
        meta: { target: ['sku'] },
        clientVersion: '6.0.0',
      });
      prisma.product.create.mockRejectedValue(error);
      await expect(
        service.create({ name: 'Test', sku: 'DUP', barcode: 'x' }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('update', () => {
    it('updates only provided fields', async () => {
      prisma.product.update.mockResolvedValue({ ...SAMPLE_PRODUCT, name: 'Updated' });
      const result = await service.update(SAMPLE_PRODUCT.id, { name: 'Updated' });
      expect(result.name).toBe('Updated');
      expect(prisma.product.update).toHaveBeenCalledWith({
        where: { id: SAMPLE_PRODUCT.id },
        data: { name: 'Updated' },
      });
    });

    it('returns existing product when no fields provided', async () => {
      prisma.product.findUnique.mockResolvedValue(SAMPLE_PRODUCT);
      const result = await service.update(SAMPLE_PRODUCT.id, {});
      expect(result).toEqual(SAMPLE_PRODUCT);
      expect(prisma.product.update).not.toHaveBeenCalled();
    });

    it('throws NotFoundException on P2025', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Not found', {
        code: 'P2025',
        meta: {},
        clientVersion: '6.0.0',
      });
      prisma.product.update.mockRejectedValue(error);
      await expect(
        service.update('nonexistent', { name: 'X' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException on duplicate barcode', async () => {
      const error = new Prisma.PrismaClientKnownRequestError('Unique', {
        code: 'P2002',
        meta: { target: ['barcode'] },
        clientVersion: '6.0.0',
      });
      prisma.product.update.mockRejectedValue(error);
      await expect(
        service.update(SAMPLE_PRODUCT.id, { barcode: 'DUP' }),
      ).rejects.toThrow(ConflictException);
    });
  });

  describe('remove', () => {
    it('deletes when no references exist', async () => {
      prisma.product.findUnique.mockResolvedValue({
        ...SAMPLE_PRODUCT,
        _count: { inventoryItems: 0, orderItems: 0 },
      });
      prisma.product.delete.mockResolvedValue(SAMPLE_PRODUCT);
      await service.remove(SAMPLE_PRODUCT.id);
      expect(prisma.product.delete).toHaveBeenCalledWith({
        where: { id: SAMPLE_PRODUCT.id },
      });
    });

    it('throws NotFoundException when product missing', async () => {
      prisma.product.findUnique.mockResolvedValue(null);
      await expect(service.remove('nonexistent')).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when inventory items reference product', async () => {
      prisma.product.findUnique.mockResolvedValue({
        ...SAMPLE_PRODUCT,
        _count: { inventoryItems: 3, orderItems: 0 },
      });
      await expect(service.remove(SAMPLE_PRODUCT.id)).rejects.toThrow(ConflictException);
      expect(prisma.product.delete).not.toHaveBeenCalled();
    });

    it('throws ConflictException when order items reference product', async () => {
      prisma.product.findUnique.mockResolvedValue({
        ...SAMPLE_PRODUCT,
        _count: { inventoryItems: 0, orderItems: 5 },
      });
      await expect(service.remove(SAMPLE_PRODUCT.id)).rejects.toThrow(ConflictException);
    });
  });
});
