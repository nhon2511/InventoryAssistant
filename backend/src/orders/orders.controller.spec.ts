import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Test } from '@nestjs/testing';
import {
  ConflictException,
  InternalServerErrorException,
  NotFoundException,
} from '@nestjs/common';
import { OrdersController } from './orders.controller.js';
import { OrdersService } from './orders.service.js';
import { OrderConfirmationService } from '../inventory-contract/order-confirmation.service.js';
import type { AuthenticatedRequest } from '../auth/authentication.guard.js';
import { ConfirmationTypeDto } from './dto/confirm-order.dto.js';
import { VERIFIED_PRINCIPAL_PROVIDER } from '../inventory-contract/inventory-command.service.js';
import { Reflector } from '@nestjs/core';

function makeRequest(
  overrides?: Partial<AuthenticatedRequest>,
): AuthenticatedRequest {
  return {
    headers: { authorization: 'Bearer test.jwt.token' },
    verifiedPrincipal: {
      subjectId: '550e8400-e29b-41d4-a716-446655440001',
      scopeId: '550e8400-e29b-41d4-a716-446655440001',
      issuer: 'https://test.supabase.co/auth/v1',
      audience: 'authenticated',
      authorizationSource: 'verified-jwt',
      trustedRole: 'ADMIN',
    },
    ...overrides,
  };
}

const SAMPLE_ORDER = {
  id: '770e8400-e29b-41d4-a716-446655440001',
  orderCode: 'INB-202611-0001',
  type: 'INBOUND',
  status: 'DRAFT',
  createdBy: '880e8400-e29b-41d4-a716-446655440001',
  approvedBy: null,
  note: 'Nhập hàng',
  createdAt: new Date('2026-11-01'),
  updatedAt: new Date('2026-11-01'),
  _count: { items: 1 },
};
const confirmLines = [
  { lineId: '990e8400-e29b-41d4-a716-446655440001', actualQuantity: 2 },
];

describe('OrdersController', () => {
  let controller: OrdersController;
  let confirmSpy: ReturnType<typeof vi.fn>;
  let ordersServiceMock: {
    findAll: ReturnType<typeof vi.fn>;
    findById: ReturnType<typeof vi.fn>;
    createDraft: ReturnType<typeof vi.fn>;
    reviewOrder: ReturnType<typeof vi.fn>;
  };

  beforeEach(async () => {
    confirmSpy = vi.fn();
    ordersServiceMock = {
      findAll: vi.fn(),
      findById: vi.fn(),
      createDraft: vi.fn(),
      reviewOrder: vi.fn(),
    };

    const moduleRef = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        {
          provide: OrderConfirmationService,
          useValue: { confirm: confirmSpy },
        },
        {
          provide: OrdersService,
          useValue: ordersServiceMock,
        },
        {
          provide: VERIFIED_PRINCIPAL_PROVIDER,
          useValue: { verifyAccessToken: vi.fn() },
        },
        Reflector,
      ],
    }).compile();

    controller = moduleRef.get(OrdersController);
  });

  describe('findAll', () => {
    it('returns orders list matching query', async () => {
      ordersServiceMock.findAll.mockResolvedValue([SAMPLE_ORDER]);

      const result = await controller.findAll({}, makeRequest());

      expect(result).toEqual([SAMPLE_ORDER]);
      expect(ordersServiceMock.findAll).toHaveBeenCalledWith(
        {},
        '550e8400-e29b-41d4-a716-446655440001',
        'ADMIN',
      );
    });
    it('does not query orders without a verified principal', async () => {
      await expect(
        controller.findAll({}, makeRequest({ verifiedPrincipal: undefined })),
      ).rejects.toThrow(InternalServerErrorException);
      expect(ordersServiceMock.findAll).not.toHaveBeenCalled();
    });
  });

  describe('findOne', () => {
    it('returns order details by id', async () => {
      ordersServiceMock.findById.mockResolvedValue(SAMPLE_ORDER);

      const result = await controller.findOne(
        { id: SAMPLE_ORDER.id },
        makeRequest(),
      );

      expect(result).toEqual(SAMPLE_ORDER);
      expect(ordersServiceMock.findById).toHaveBeenCalledWith(
        SAMPLE_ORDER.id,
        '550e8400-e29b-41d4-a716-446655440001',
        'ADMIN',
      );
    });

    it('throws NotFoundException when order not found', async () => {
      ordersServiceMock.findById.mockRejectedValue(
        new NotFoundException('Order not found'),
      );

      await expect(
        controller.findOne({ id: 'nonexistent' }, makeRequest()),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('createDraft', () => {
    it('creates draft order with authenticated user as createdBy', async () => {
      ordersServiceMock.createDraft.mockResolvedValue(SAMPLE_ORDER);

      const dto = {
        type: 'INBOUND' as const,
        items: [
          {
            productId: '550e8400-e29b-41d4-a716-446655440001',
            expectedQuantity: 10,
          },
        ],
      };

      const result = await controller.createDraft(dto as never, makeRequest());

      expect(result).toEqual(SAMPLE_ORDER);
      expect(ordersServiceMock.createDraft).toHaveBeenCalledWith(
        dto,
        '550e8400-e29b-41d4-a716-446655440001',
      );
    });
  });

  describe('reviewOrder', () => {
    it('reviews order successfully with approve = true', async () => {
      const approvedOrder = { ...SAMPLE_ORDER, status: 'CONFIRMED' };
      ordersServiceMock.reviewOrder.mockResolvedValue(approvedOrder);

      const result = await controller.reviewOrder(
        { id: SAMPLE_ORDER.id },
        { approve: true },
        makeRequest(),
      );

      expect(result).toEqual(approvedOrder);
      expect(ordersServiceMock.reviewOrder).toHaveBeenCalledWith(
        SAMPLE_ORDER.id,
        true,
        '550e8400-e29b-41d4-a716-446655440001',
      );
    });

    it('throws InternalServerErrorException when principal is missing', async () => {
      await expect(
        controller.reviewOrder(
          { id: SAMPLE_ORDER.id },
          { approve: true },
          makeRequest({ verifiedPrincipal: undefined }),
        ),
      ).rejects.toThrow(InternalServerErrorException);
    });
  });

  it('returns applied result on successful confirmation', async () => {
    const result = {
      kind: 'applied' as const,
      orderId: 'order-1',
      movements: 3,
    };
    confirmSpy.mockResolvedValue(result);

    const response = await controller.confirm(
      { orderId: 'order-1' },
      {
        type: ConfirmationTypeDto.INBOUND,
        idempotencyKey: 'key-1',
        lines: confirmLines,
      },
      makeRequest(),
    );

    expect(response).toEqual({
      kind: 'applied',
      orderId: 'order-1',
      movements: 3,
    });
    expect(confirmSpy).toHaveBeenCalledWith('test.jwt.token', {
      orderId: 'order-1',
      type: 'INBOUND',
      idempotencyKey: 'key-1',
      lines: confirmLines,
    });
  });

  it('returns replay result on idempotent retry', async () => {
    const result = {
      kind: 'replay' as const,
      orderId: 'order-1',
      movements: 2,
    };
    confirmSpy.mockResolvedValue(result);

    const response = await controller.confirm(
      { orderId: 'order-1' },
      {
        type: ConfirmationTypeDto.OUTBOUND,
        idempotencyKey: 'key-1',
        lines: confirmLines,
      },
      makeRequest(),
    );

    expect(response).toEqual({
      kind: 'replay',
      orderId: 'order-1',
      movements: 2,
    });
  });

  it('throws ConflictException on idempotency conflict', async () => {
    confirmSpy.mockResolvedValue({ kind: 'conflict' });

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.INBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws ConflictException on in_progress', async () => {
    confirmSpy.mockResolvedValue({ kind: 'in_progress' });

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.INBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws ConflictException on expired key', async () => {
    confirmSpy.mockResolvedValue({ kind: 'expired' });

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.INBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws NotFoundException on missing order', async () => {
    confirmSpy.mockRejectedValue(new Error('Order not found'));

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.INBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest(),
      ),
    ).rejects.toThrow(NotFoundException);
  });

  it('throws ConflictException on insufficient stock', async () => {
    confirmSpy.mockRejectedValue(new Error('Insufficient available stock'));

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.OUTBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws InternalServerErrorException on unknown error', async () => {
    confirmSpy.mockRejectedValue(new Error('Some database connection failed'));

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.INBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest(),
      ),
    ).rejects.toThrow(InternalServerErrorException);
  });

  it('throws InternalServerErrorException if principal is missing', async () => {
    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        {
          type: ConfirmationTypeDto.INBOUND,
          idempotencyKey: 'key-1',
          lines: confirmLines,
        },
        makeRequest({ verifiedPrincipal: undefined }),
      ),
    ).rejects.toThrow(InternalServerErrorException);
  });
});
