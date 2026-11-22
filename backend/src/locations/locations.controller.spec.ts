import { ConflictException, NotFoundException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Test } from '@nestjs/testing';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import { VERIFIED_PRINCIPAL_PROVIDER } from '../inventory-contract/inventory-command.service.js';
import { LocationsController } from './locations.controller.js';
import { LocationsService } from './locations.service.js';

const SAMPLE = {
  id: '660e8400-e29b-41d4-a716-446655440001',
  zoneCode: 'Z-A',
  aisleCode: 'A-01',
  rackCode: 'R-01',
  binCode: 'B-01',
  locationBarcode: 'LOC-ZA-A01-R01-B01',
  maxCapacityKg: null,
  createdAt: new Date('2026-01-01'),
};

describe('LocationsController', () => {
  let controller: LocationsController;
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
      controllers: [LocationsController],
      providers: [
        { provide: LocationsService, useValue: service },
        { provide: VERIFIED_PRINCIPAL_PROVIDER, useValue: { verifyAccessToken: vi.fn() } },
        Reflector,
      ],
    }).compile();

    controller = moduleRef.get(LocationsController);
  });

  it('findAll returns location list', async () => {
    service.findAll.mockResolvedValue([SAMPLE]);
    expect(await controller.findAll()).toEqual([SAMPLE]);
  });

  it('findOne returns a location by id', async () => {
    service.findById.mockResolvedValue(SAMPLE);
    expect(await controller.findOne({ id: SAMPLE.id })).toEqual(SAMPLE);
    expect(service.findById).toHaveBeenCalledWith(SAMPLE.id);
  });

  it('findOne throws NotFoundException', async () => {
    service.findById.mockRejectedValue(new NotFoundException('Not found'));
    await expect(controller.findOne({ id: 'nonexistent' })).rejects.toThrow(NotFoundException);
  });

  it('create returns created location', async () => {
    service.create.mockResolvedValue(SAMPLE);
    const dto = {
      zoneCode: 'Z-A',
      aisleCode: 'A-01',
      rackCode: 'R-01',
      binCode: 'B-01',
      locationBarcode: 'LOC-ZA-A01-R01-B01',
    };
    expect(await controller.create(dto)).toEqual(SAMPLE);
  });

  it('create throws ConflictException on duplicate', async () => {
    service.create.mockRejectedValue(new ConflictException('Duplicate barcode'));
    await expect(
      controller.create({
        zoneCode: 'Z-A',
        aisleCode: 'A-01',
        rackCode: 'R-01',
        binCode: 'B-01',
        locationBarcode: 'LOC-DUP',
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('update returns updated location', async () => {
    const updated = { ...SAMPLE, binCode: 'B-02' };
    service.update.mockResolvedValue(updated);
    expect(await controller.update({ id: SAMPLE.id }, { binCode: 'B-02' })).toEqual(updated);
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
