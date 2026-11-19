import { describe, it, expect, vi, beforeEach } from 'vitest';
import { Test } from '@nestjs/testing';
import { ConflictException, InternalServerErrorException } from '@nestjs/common';
import { OrdersController } from './orders.controller.js';
import { OrderConfirmationService } from '../inventory-contract/order-confirmation.service.js';
import type { AuthenticatedRequest } from '../auth/authentication.guard.js';
import { ConfirmationTypeDto } from './dto/confirm-order.dto.js';
import { VERIFIED_PRINCIPAL_PROVIDER } from '../inventory-contract/inventory-command.service.js';
import { Reflector } from '@nestjs/core';

function makeRequest(overrides?: Partial<AuthenticatedRequest>): AuthenticatedRequest {
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

describe('OrdersController', () => {
  let controller: OrdersController;
  let confirmSpy: ReturnType<typeof vi.fn>;

  beforeEach(async () => {
    confirmSpy = vi.fn();

    const moduleRef = await Test.createTestingModule({
      controllers: [OrdersController],
      providers: [
        {
          provide: OrderConfirmationService,
          useValue: { confirm: confirmSpy },
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

  it('returns applied result on successful confirmation', async () => {
    const result = { kind: 'applied' as const, orderId: 'order-1', movements: 3 };
    confirmSpy.mockResolvedValue(result);

    const response = await controller.confirm(
      { orderId: 'order-1' },
      { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
      makeRequest(),
    );

    expect(response).toEqual({ kind: 'applied', orderId: 'order-1', movements: 3 });
    expect(confirmSpy).toHaveBeenCalledWith('test.jwt.token', {
      orderId: 'order-1',
      type: 'INBOUND',
      idempotencyKey: 'key-1',
    });
  });

  it('returns replay result on idempotent retry', async () => {
    const result = { kind: 'replay' as const, orderId: 'order-1', movements: 2 };
    confirmSpy.mockResolvedValue(result);

    const response = await controller.confirm(
      { orderId: 'order-1' },
      { type: ConfirmationTypeDto.OUTBOUND, idempotencyKey: 'key-1' },
      makeRequest(),
    );

    expect(response).toEqual({ kind: 'replay', orderId: 'order-1', movements: 2 });
  });

  it('throws ConflictException on idempotency conflict', async () => {
    confirmSpy.mockResolvedValue({ kind: 'conflict' });

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws ConflictException on in_progress', async () => {
    confirmSpy.mockResolvedValue({ kind: 'in_progress' });

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws ConflictException on expired key', async () => {
    confirmSpy.mockResolvedValue({ kind: 'expired' });

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws ConflictException on domain error (order not found)', async () => {
    confirmSpy.mockRejectedValue(new Error('Order not found'));

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws ConflictException on insufficient stock', async () => {
    confirmSpy.mockRejectedValue(new Error('Insufficient available stock'));

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.OUTBOUND, idempotencyKey: 'key-1' },
        makeRequest(),
      ),
    ).rejects.toThrow(ConflictException);
  });

  it('throws InternalServerErrorException on unknown error', async () => {
    confirmSpy.mockRejectedValue(new Error('Some database connection failed'));

    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
        makeRequest(),
      ),
    ).rejects.toThrow(InternalServerErrorException);
  });

  it('throws InternalServerErrorException if principal is missing', async () => {
    await expect(
      controller.confirm(
        { orderId: 'order-1' },
        { type: ConfirmationTypeDto.INBOUND, idempotencyKey: 'key-1' },
        makeRequest({ verifiedPrincipal: undefined }),
      ),
    ).rejects.toThrow(InternalServerErrorException);
  });
});
