import { NotFoundException, UnprocessableEntityException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { VERIFIED_PRINCIPAL_PROVIDER } from '../inventory-contract/inventory-command.service.js';
import { InventoryController } from './inventory.controller.js';
import { InventoryService } from './inventory.service.js';

const SAMPLE_ITEM = {
  id: 'aa0e8400-e29b-41d4-a716-446655440001',
  productId: '550e8400-e29b-41d4-a716-446655440001',
  locationId: '660e8400-e29b-41d4-a716-446655440001',
  quantityOnHand: 100,
  quantityReserved: 20,
  lotNumber: 'LOT-202611-01',
  expiryDate: new Date('2027-11-22'),
  updatedAt: new Date('2026-11-01'),
};

describe('InventoryController', () => {
  let controller: InventoryController;
  let service: Record<string, ReturnType<typeof vi.fn>>;

  beforeEach(async () => {
    service = {
      receive: vi.fn(),
      ship: vi.fn(),
      getStock: vi.fn(),
    };

    const moduleRef = await Test.createTestingModule({
      controllers: [InventoryController],
      providers: [
        { provide: InventoryService, useValue: service },
        { provide: VERIFIED_PRINCIPAL_PROVIDER, useValue: { verifyAccessToken: vi.fn() } },
        Reflector,
      ],
    }).compile();

    controller = moduleRef.get(InventoryController);
  });

  describe('receive', () => {
    it('calls service.receive and returns updated item', async () => {
      service.receive.mockResolvedValue(SAMPLE_ITEM);
      const dto = {
        productId: SAMPLE_ITEM.productId,
        locationId: SAMPLE_ITEM.locationId,
        quantity: 50,
      };

      const result = await controller.receive(dto);

      expect(result).toEqual(SAMPLE_ITEM);
      expect(service.receive).toHaveBeenCalledWith(dto);
    });

    it('throws NotFoundException when referenced entity missing', async () => {
      service.receive.mockRejectedValue(new NotFoundException('Product not found'));

      await expect(
        controller.receive({
          productId: 'nonexistent',
          locationId: SAMPLE_ITEM.locationId,
          quantity: 10,
        }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('ship', () => {
    it('calls service.ship and returns updated item', async () => {
      service.ship.mockResolvedValue(SAMPLE_ITEM);
      const dto = {
        productId: SAMPLE_ITEM.productId,
        locationId: SAMPLE_ITEM.locationId,
        quantity: 10,
      };

      const result = await controller.ship(dto);

      expect(result).toEqual(SAMPLE_ITEM);
      expect(service.ship).toHaveBeenCalledWith(dto);
    });

    it('throws UnprocessableEntityException when stock insufficient', async () => {
      service.ship.mockRejectedValue(
        new UnprocessableEntityException('Insufficient available inventory'),
      );

      await expect(
        controller.ship({
          productId: SAMPLE_ITEM.productId,
          locationId: SAMPLE_ITEM.locationId,
          quantity: 999,
        }),
      ).rejects.toThrow(UnprocessableEntityException);
    });
  });

  describe('getStock', () => {
    it('calls service.getStock and returns list', async () => {
      service.getStock.mockResolvedValue([SAMPLE_ITEM]);

      const result = await controller.getStock({});

      expect(result).toEqual([SAMPLE_ITEM]);
      expect(service.getStock).toHaveBeenCalledWith({});
    });
  });
});
