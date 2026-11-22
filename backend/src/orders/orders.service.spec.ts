import { NotFoundException } from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { OrderStatusEnum, OrderTypeEnum } from './dto/order-query.dto.js';
import { OrdersService } from './orders.service.js';

function makePrisma() {
  return {
    warehouseOrder: {
      findMany: vi.fn(),
      findUnique: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
    },
  };
}

const SAMPLE_ORDER = {
  id: '770e8400-e29b-41d4-a716-446655440001',
  orderCode: 'INB-202611-0001',
  type: 'INBOUND',
  status: 'DRAFT',
  createdBy: '880e8400-e29b-41d4-a716-446655440001',
  approvedBy: null,
  note: 'Nhập hàng đầu tháng',
  createdAt: new Date('2026-11-01'),
  updatedAt: new Date('2026-11-01'),
  _count: { items: 2 },
};

const SAMPLE_ORDER_DETAIL = {
  ...SAMPLE_ORDER,
  items: [
    {
      id: '990e8400-e29b-41d4-a716-446655440001',
      orderId: SAMPLE_ORDER.id,
      productId: '550e8400-e29b-41d4-a716-446655440001',
      locationId: '660e8400-e29b-41d4-a716-446655440001',
      expectedQuantity: 50,
      actualQuantity: 0,
      lotNumber: 'LOT-01',
      expiryDate: new Date('2027-01-01'),
      createdAt: new Date('2026-11-01'),
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
    },
  ],
};

describe('OrdersService', () => {
  let service: OrdersService;
  let prisma: ReturnType<typeof makePrisma>;

  beforeEach(() => {
    prisma = makePrisma();
    service = new OrdersService(prisma as never);
  });

  describe('findAll', () => {
    it('returns orders list without filters', async () => {
      prisma.warehouseOrder.findMany.mockResolvedValue([SAMPLE_ORDER]);

      const result = await service.findAll({});

      expect(result).toEqual([SAMPLE_ORDER]);
      expect(prisma.warehouseOrder.findMany).toHaveBeenCalledWith({
        where: {},
        orderBy: { createdAt: 'desc' },
        include: { _count: { select: { items: true } } },
      });
    });

    it('applies type, status, createdBy, and search filters', async () => {
      prisma.warehouseOrder.findMany.mockResolvedValue([SAMPLE_ORDER]);

      const query = {
        type: OrderTypeEnum.INBOUND,
        status: OrderStatusEnum.DRAFT,
        createdBy: '880e8400-e29b-41d4-a716-446655440001',
        search: 'INB-2026',
      };

      const result = await service.findAll(query);

      expect(result).toEqual([SAMPLE_ORDER]);
      expect(prisma.warehouseOrder.findMany).toHaveBeenCalledWith({
        where: {
          type: 'INBOUND',
          status: 'DRAFT',
          createdBy: '880e8400-e29b-41d4-a716-446655440001',
          OR: [
            { orderCode: { contains: 'INB-2026', mode: 'insensitive' } },
            { note: { contains: 'INB-2026', mode: 'insensitive' } },
          ],
        },
        orderBy: { createdAt: 'desc' },
        include: { _count: { select: { items: true } } },
      });
    });
  });

  describe('findById', () => {
    it('finds order by UUID with items, product, and location details', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue(SAMPLE_ORDER_DETAIL);

      const result = await service.findById(SAMPLE_ORDER.id);

      expect(result).toEqual(SAMPLE_ORDER_DETAIL);
      expect(prisma.warehouseOrder.findUnique).toHaveBeenCalledWith({
        where: { id: SAMPLE_ORDER.id },
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

    it('finds order by orderCode', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue(SAMPLE_ORDER_DETAIL);

      const result = await service.findById('INB-202611-0001');

      expect(result).toEqual(SAMPLE_ORDER_DETAIL);
      expect(prisma.warehouseOrder.findUnique).toHaveBeenCalledWith({
        where: { orderCode: 'INB-202611-0001' },
        include: expect.any(Object),
      });
    });

    it('throws NotFoundException when order does not exist', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue(null);

      await expect(service.findById('nonexistent')).rejects.toThrow(NotFoundException);
    });
  });
});
