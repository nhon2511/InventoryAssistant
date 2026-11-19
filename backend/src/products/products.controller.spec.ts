import { ConflictException, NotFoundException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { VERIFIED_PRINCIPAL_PROVIDER } from '../inventory-contract/inventory-command.service.js';
import { ProductsController } from './products.controller.js';
import { ProductsService } from './products.service.js';

const SAMPLE = {
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

describe('ProductsController', () => {
  let controller: ProductsController;
  let service: Record<string, ReturnType<typeof vi.fn>>;

  beforeEach(async () => {
    service = {
      findAll: vi.fn(),
      findById: vi.fn(),
      create: vi.fn(),
      update: vi.fn(),
      remove: vi.fn(),
    };

    const moduleRef = await Test.createTestingModule({
      controllers: [ProductsController],
      providers: [
        { provide: ProductsService, useValue: service },
        { provide: VERIFIED_PRINCIPAL_PROVIDER, useValue: { verifyAccessToken: vi.fn() } },
        Reflector,
      ],
    }).compile();

    controller = moduleRef.get(ProductsController);
  });

  it('findAll returns product list', async () => {
    service.findAll.mockResolvedValue([SAMPLE]);
    expect(await controller.findAll()).toEqual([SAMPLE]);
  });

  it('findOne returns a product by id', async () => {
    service.findById.mockResolvedValue(SAMPLE);
    expect(await controller.findOne({ id: SAMPLE.id })).toEqual(SAMPLE);
    expect(service.findById).toHaveBeenCalledWith(SAMPLE.id);
  });

  it('findOne throws NotFoundException', async () => {
    service.findById.mockRejectedValue(new NotFoundException('Not found'));
    await expect(controller.findOne({ id: 'x' })).rejects.toThrow(NotFoundException);
  });

  it('create returns created product', async () => {
    service.create.mockResolvedValue(SAMPLE);
    const dto = { name: 'Mì Hảo Hảo', sku: 'SKU-001', barcode: '8934563118020' };
    expect(await controller.create(dto)).toEqual(SAMPLE);
  });

  it('create throws ConflictException on duplicate', async () => {
    service.create.mockRejectedValue(new ConflictException('Duplicate sku'));
    await expect(
      controller.create({ name: 'X', sku: 'DUP', barcode: 'Y' }),
    ).rejects.toThrow(ConflictException);
  });

  it('update returns updated product', async () => {
    const updated = { ...SAMPLE, name: 'Updated' };
    service.update.mockResolvedValue(updated);
    expect(await controller.update({ id: SAMPLE.id }, { name: 'Updated' })).toEqual(updated);
  });

  it('remove calls service.remove', async () => {
    service.remove.mockResolvedValue(undefined);
    await controller.remove({ id: SAMPLE.id });
    expect(service.remove).toHaveBeenCalledWith(SAMPLE.id);
  });

  it('remove throws ConflictException when references exist', async () => {
    service.remove.mockRejectedValue(new ConflictException('Has references'));
    await expect(controller.remove({ id: SAMPLE.id })).rejects.toThrow(ConflictException);
  });
});
