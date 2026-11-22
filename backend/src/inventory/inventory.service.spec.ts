import { NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { InventoryService } from './inventory.service.js';

function makePrisma() {
  const inventoryItem = {
    findMany: vi.fn(),
    findFirst: vi.fn(),
    findUnique: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
  };
  const product = {
    findUnique: vi.fn(),
  };
  const location = {
    findUnique: vi.fn(),
  };

  const tx = {
    inventoryItem,
  };

  return {
    inventoryItem,
    product,
    location,
    $transaction: vi.fn((fn: (innerTx: typeof tx) => unknown) => fn(tx)),
  };
}

const SAMPLE_ITEM = {
  id: 'aa0e8400-e29b-41d4-a716-446655440001',
  productId: '550e8400-e29b-41d4-a716-446655440001',
  locationId: '660e8400-e29b-41d4-a716-446655440001',
  quantityOnHand: 100,
  quantityReserved: 20,
  lotNumber: 'LOT-202611-01',
  expiryDate: new Date('2027-11-22'),
  updatedAt: new Date('2026-11-01'),
  product: {
    id: '550e8400-e29b-41d4-a716-446655440001',
    name: 'Mì Hảo Hảo',
    sku: 'SKU-001',
    barcode: '8934563118020',
    unit: 'Thùng',
  },
  location: {
    id: '660e8400-e29b-41d4-a716-446655440001',
    locationBarcode: 'LOC-ZA-A01-R01-B01',
    zoneCode: 'Z-A',
    aisleCode: 'A-01',
    rackCode: 'R-01',
    binCode: 'B-01',
  },
};

describe('InventoryService', () => {
  let service: InventoryService;
  let prisma: ReturnType<typeof makePrisma>;

  beforeEach(() => {
    prisma = makePrisma();
    service = new InventoryService(prisma as never);
  });

  describe('receive', () => {
    const receiveDto = {
      productId: '550e8400-e29b-41d4-a716-446655440001',
      locationId: '660e8400-e29b-41d4-a716-446655440001',
      quantity: 50,
      lotNumber: 'LOT-202611-01',
      expiryDate: '2027-11-22',
    };

    it('increments quantityOnHand when inventory item already exists', async () => {
      prisma.product.findUnique.mockResolvedValue({ id: receiveDto.productId });
      prisma.location.findUnique.mockResolvedValue({ id: receiveDto.locationId });
      prisma.inventoryItem.findFirst.mockResolvedValue(SAMPLE_ITEM);
      prisma.inventoryItem.update.mockResolvedValue({
        ...SAMPLE_ITEM,
        quantityOnHand: 150,
      });

      const result = await service.receive(receiveDto);

      expect(result.quantityOnHand).toBe(150);
      expect(prisma.inventoryItem.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: SAMPLE_ITEM.id },
          data: {
            quantityOnHand: { increment: 50 },
            expiryDate: new Date('2027-11-22'),
          },
        }),
      );
    });

    it('creates new inventory item when it does not exist yet', async () => {
      prisma.product.findUnique.mockResolvedValue({ id: receiveDto.productId });
      prisma.location.findUnique.mockResolvedValue({ id: receiveDto.locationId });
      prisma.inventoryItem.findFirst.mockResolvedValue(null);
      prisma.inventoryItem.create.mockResolvedValue({
        ...SAMPLE_ITEM,
        quantityOnHand: 50,
        quantityReserved: 0,
      });

      const result = await service.receive(receiveDto);

      expect(result.quantityOnHand).toBe(50);
      expect(prisma.inventoryItem.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: {
            productId: receiveDto.productId,
            locationId: receiveDto.locationId,
            quantityOnHand: 50,
            quantityReserved: 0,
            lotNumber: receiveDto.lotNumber,
            expiryDate: new Date('2027-11-22'),
          },
        }),
      );
    });

    it('throws NotFoundException when product does not exist', async () => {
      prisma.product.findUnique.mockResolvedValue(null);

      await expect(service.receive(receiveDto)).rejects.toThrow(NotFoundException);
      expect(prisma.inventoryItem.findFirst).not.toHaveBeenCalled();
    });

    it('throws NotFoundException when location does not exist', async () => {
      prisma.product.findUnique.mockResolvedValue({ id: receiveDto.productId });
      prisma.location.findUnique.mockResolvedValue(null);

      await expect(service.receive(receiveDto)).rejects.toThrow(NotFoundException);
      expect(prisma.inventoryItem.findFirst).not.toHaveBeenCalled();
    });
  });

  describe('ship', () => {
    const shipDto = {
      productId: '550e8400-e29b-41d4-a716-446655440001',
      locationId: '660e8400-e29b-41d4-a716-446655440001',
      quantity: 30,
      lotNumber: 'LOT-202611-01',
    };

    it('decrements quantityOnHand when available stock is sufficient', async () => {
      // available = 100 - 20 = 80 >= 30
      prisma.inventoryItem.findFirst.mockResolvedValue(SAMPLE_ITEM);
      prisma.inventoryItem.update.mockResolvedValue({
        ...SAMPLE_ITEM,
        quantityOnHand: 70,
      });

      const result = await service.ship(shipDto);

      expect(result.quantityOnHand).toBe(70);
      expect(prisma.inventoryItem.update).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { id: SAMPLE_ITEM.id },
          data: {
            quantityOnHand: { decrement: 30 },
          },
        }),
      );
    });

    it('throws UnprocessableEntityException when available stock is insufficient', async () => {
      // available = 100 - 20 = 80 < 90
      prisma.inventoryItem.findFirst.mockResolvedValue(SAMPLE_ITEM);

      await expect(service.ship({ ...shipDto, quantity: 90 })).rejects.toThrow(
        UnprocessableEntityException,
      );
      expect(prisma.inventoryItem.update).not.toHaveBeenCalled();
    });

    it('throws NotFoundException when inventory item does not exist', async () => {
      prisma.inventoryItem.findFirst.mockResolvedValue(null);

      await expect(service.ship(shipDto)).rejects.toThrow(NotFoundException);
    });
  });

  describe('getStock', () => {
    it('returns all stock when no filters provided', async () => {
      prisma.inventoryItem.findMany.mockResolvedValue([SAMPLE_ITEM]);

      const result = await service.getStock({});

      expect(result).toEqual([SAMPLE_ITEM]);
      expect(prisma.inventoryItem.findMany).toHaveBeenCalledWith({
        where: {},
        include: expect.any(Object),
        orderBy: { updatedAt: 'desc' },
      });
    });

    it('filters stock by productId and locationId', async () => {
      prisma.inventoryItem.findMany.mockResolvedValue([SAMPLE_ITEM]);

      const query = {
        productId: SAMPLE_ITEM.productId,
        locationId: SAMPLE_ITEM.locationId,
      };

      const result = await service.getStock(query);

      expect(result).toEqual([SAMPLE_ITEM]);
      expect(prisma.inventoryItem.findMany).toHaveBeenCalledWith({
        where: {
          productId: SAMPLE_ITEM.productId,
          locationId: SAMPLE_ITEM.locationId,
        },
        include: expect.any(Object),
        orderBy: { updatedAt: 'desc' },
      });
    });
  });
});
