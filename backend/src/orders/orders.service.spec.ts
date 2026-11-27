import { ConflictException, NotFoundException } from '@nestjs/common';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { OrderStatusEnum, OrderTypeEnum } from './dto/order-query.dto.js';
import { OrdersService } from './orders.service.js';

function makePrisma() {
  const warehouseOrder = {
    findMany: vi.fn(),
    findUnique: vi.fn(),
    findFirst: vi.fn(),
    create: vi.fn(),
    update: vi.fn(),
    updateMany: vi.fn(),
  };
  const product = {
    findMany: vi.fn(),
  };
  const location = {
    findMany: vi.fn(),
  };

  const tx = {
    warehouseOrder,
    product,
    location,
  };

  return {
    warehouseOrder,
    product,
    location,
    $transaction: vi.fn((fn: (innerTx: typeof tx) => unknown) => fn(tx)),
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
    it('scopes STAFF list to verified actor despite client createdBy filter', async () => {
      prisma.warehouseOrder.findMany.mockResolvedValue([]);
      await service.findAll(
        { createdBy: 'other-user' },
        'verified-user',
        'STAFF',
      );
      expect(prisma.warehouseOrder.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: { createdBy: 'verified-user' },
        }),
      );
    });
    it('returns orders list without filters', async () => {
      prisma.warehouseOrder.findMany.mockResolvedValue([SAMPLE_ORDER]);

      const result = await service.findAll({});

      expect(result).toEqual([SAMPLE_ORDER]);
      expect(prisma.warehouseOrder.findMany).toHaveBeenCalledWith({
        where: {},
        orderBy: { createdAt: 'desc' },
        include: {
          items: { include: { product: true, location: true } },
          _count: { select: { items: true } },
        },
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
        include: {
          items: { include: { product: true, location: true } },
          _count: { select: { items: true } },
        },
      });
    });
  });

  describe('findById', () => {
    it('hides another actor order from STAFF', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue(SAMPLE_ORDER_DETAIL);
      await expect(
        service.findById(SAMPLE_ORDER.id, 'other-user', 'STAFF'),
      ).rejects.toThrow(NotFoundException);
    });
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

      await expect(service.findById('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('createDraft', () => {
    const draftDto = {
      type: OrderTypeEnum.INBOUND,
      note: 'Phiếu nhập nháp',
      requestId: '770e8400-e29b-41d4-a716-446655440099',
      items: [
        {
          productId: '550e8400-e29b-41d4-a716-446655440001',
          locationId: '660e8400-e29b-41d4-a716-446655440001',
          expectedQuantity: 20,
          lotNumber: 'LOT-A',
          expiryDate: '2027-12-31',
        },
      ],
    };

    it('creates draft order atomically when product and location exist', async () => {
      prisma.product.findMany.mockResolvedValue([
        { id: draftDto.items[0].productId },
      ]);
      prisma.location.findMany.mockResolvedValue([
        { id: draftDto.items[0].locationId },
      ]);
      prisma.warehouseOrder.findFirst.mockResolvedValue({
        orderCode: 'INB-202611-0003',
      });
      prisma.warehouseOrder.create.mockResolvedValue(SAMPLE_ORDER_DETAIL);

      const result = await service.createDraft(draftDto, 'user-actor-id');

      expect(result).toEqual(SAMPLE_ORDER_DETAIL);
      expect(prisma.$transaction).toHaveBeenCalled();
      expect(prisma.warehouseOrder.create).toHaveBeenCalledWith(
        expect.objectContaining({
          data: expect.objectContaining({
            orderCode: expect.stringMatching(/^INB-\d{6}-0004$/),
            type: 'INBOUND',
            status: 'DRAFT',
            createdBy: 'user-actor-id',
            id: draftDto.requestId,
          }),
        }),
      );
    });

    it('replays a matching multi-line draft without another insert', async () => {
      const twoLines = {
        ...draftDto,
        items: [
          draftDto.items[0],
          {
            ...draftDto.items[0],
            productId: '550e8400-e29b-41d4-a716-446655440002',
            expectedQuantity: 3,
          },
        ],
      };
      const persisted = {
        ...SAMPLE_ORDER_DETAIL,
        id: draftDto.requestId,
        createdBy: 'user-actor-id',
        note: draftDto.note,
        items: twoLines.items.map((item) => ({
          ...item,
          expiryDate: new Date(item.expiryDate),
        })),
      };
      prisma.warehouseOrder.findUnique.mockResolvedValue(persisted);
      const result = await service.createDraft(twoLines, 'user-actor-id');
      expect(result).toEqual(persisted);
      expect(prisma.warehouseOrder.create).not.toHaveBeenCalled();
    });

    it('rejects reused request ID with changed lines or actor', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue({
        ...SAMPLE_ORDER_DETAIL,
        id: draftDto.requestId,
        createdBy: 'user-actor-id',
        note: draftDto.note,
        items: draftDto.items.map((item) => ({
          ...item,
          expiryDate: new Date(item.expiryDate),
        })),
      });
      await expect(
        service.createDraft(
          {
            ...draftDto,
            items: [{ ...draftDto.items[0], expectedQuantity: 21 }],
          },
          'user-actor-id',
        ),
      ).rejects.toThrow(ConflictException);
      await expect(service.createDraft(draftDto, 'other-user')).rejects.toThrow(
        ConflictException,
      );
      expect(prisma.warehouseOrder.create).not.toHaveBeenCalled();
    });

    it('throws NotFoundException when product does not exist', async () => {
      prisma.product.findMany.mockResolvedValue([]);

      await expect(
        service.createDraft(draftDto, 'user-actor-id'),
      ).rejects.toThrow(NotFoundException);
      expect(prisma.warehouseOrder.create).not.toHaveBeenCalled();
    });

    it('throws NotFoundException when location does not exist', async () => {
      prisma.product.findMany.mockResolvedValue([
        { id: draftDto.items[0].productId },
      ]);
      prisma.location.findMany.mockResolvedValue([]);

      await expect(
        service.createDraft(draftDto, 'user-actor-id'),
      ).rejects.toThrow(NotFoundException);
      expect(prisma.warehouseOrder.create).not.toHaveBeenCalled();
    });
  });

  describe('reviewOrder', () => {
    it('approves draft order and transitions status to CONFIRMED', async () => {
      prisma.warehouseOrder.findUnique
        .mockResolvedValueOnce(SAMPLE_ORDER)
        .mockResolvedValueOnce({
          ...SAMPLE_ORDER_DETAIL,
          status: 'CONFIRMED',
          approvedBy: 'approver-id',
        });
      prisma.warehouseOrder.updateMany.mockResolvedValue({ count: 1 });

      const result = await service.reviewOrder(
        SAMPLE_ORDER.id,
        true,
        'approver-id',
      );

      expect(result.status).toBe('CONFIRMED');
      expect(prisma.warehouseOrder.updateMany).toHaveBeenCalledWith({
        where: { id: SAMPLE_ORDER.id, status: 'DRAFT' },
        data: { status: 'CONFIRMED', approvedBy: 'approver-id' },
      });
    });

    it('rejects/cancels draft order and transitions status to CANCELLED', async () => {
      prisma.warehouseOrder.findUnique
        .mockResolvedValueOnce(SAMPLE_ORDER)
        .mockResolvedValueOnce({
          ...SAMPLE_ORDER_DETAIL,
          status: 'CANCELLED',
          approvedBy: null,
        });
      prisma.warehouseOrder.updateMany.mockResolvedValue({ count: 1 });

      const result = await service.reviewOrder(
        SAMPLE_ORDER.id,
        false,
        'approver-id',
      );

      expect(result.status).toBe('CANCELLED');
      expect(prisma.warehouseOrder.updateMany).toHaveBeenCalledWith({
        where: { id: SAMPLE_ORDER.id, status: 'DRAFT' },
        data: { status: 'CANCELLED', approvedBy: null },
      });
    });

    it('throws NotFoundException when order does not exist', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue(null);

      await expect(
        service.reviewOrder('nonexistent', true, 'approver-id'),
      ).rejects.toThrow(NotFoundException);
    });

    it('throws ConflictException when order is not in DRAFT status', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue({
        ...SAMPLE_ORDER,
        status: 'CONFIRMED',
      });

      await expect(
        service.reviewOrder(SAMPLE_ORDER.id, true, 'approver-id'),
      ).rejects.toThrow(ConflictException);
    });

    it('throws ConflictException when compare-and-set detects race condition', async () => {
      prisma.warehouseOrder.findUnique.mockResolvedValue(SAMPLE_ORDER);
      prisma.warehouseOrder.updateMany.mockResolvedValue({ count: 0 });

      await expect(
        service.reviewOrder(SAMPLE_ORDER.id, true, 'approver-id'),
      ).rejects.toThrow(ConflictException);
    });
  });
});
