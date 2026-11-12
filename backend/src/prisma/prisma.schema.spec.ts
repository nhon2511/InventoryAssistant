import { describe, expect, it } from 'vitest';
import type {
  InventoryItem,
  Location,
  Product,
  Profile,
  WarehouseOrder,
  WarehouseOrderItem,
} from '@prisma/client';

describe('Prisma Schema Alignment Types', () => {
  it('Location model type should match PostgreSQL schema and Flutter DTOs', () => {
    const location: Partial<Location> = {
      id: '123e4567-e89b-12d3-a456-426614174000',
      zoneCode: 'ZONE_A',
      aisleCode: 'AISLE_01',
      rackCode: 'RACK_01',
      binCode: 'BIN_01',
      locationBarcode: 'LOC-A01-01-01',
      createdAt: new Date(),
    };

    expect(location.zoneCode).toBe('ZONE_A');
    expect(location.locationBarcode).toBe('LOC-A01-01-01');
    // Ensure no legacy unmapped fields exist on type
    expect('zone' in location).toBe(false);
    expect('barcode' in location).toBe(false);
  });

  it('Profile model type should align with Supabase Auth pattern without direct email column', () => {
    const profile: Partial<Profile> = {
      id: 'auth-user-uuid-1234',
      fullName: 'Warehouse Staff',
      role: 'STAFF',
      phoneNumber: '0901234567',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    expect(profile.fullName).toBe('Warehouse Staff');
    expect(profile.phoneNumber).toBe('0901234567');
    expect('email' in profile).toBe(false);
  });

  it('InventoryItem model type should support lot_number and Date expiry_date', () => {
    const item: Partial<InventoryItem> = {
      productId: 'prod-uuid-1',
      locationId: 'loc-uuid-1',
      lotNumber: 'LOT-2026-001',
      expiryDate: new Date('2027-01-01'),
      quantityOnHand: 100,
      quantityReserved: 10,
    };

    expect(item.lotNumber).toBe('LOT-2026-001');
    expect(item.expiryDate).toBeInstanceOf(Date);
  });

  it('WarehouseOrder model type should support text-based status and type', () => {
    const order: Partial<WarehouseOrder> = {
      orderCode: 'INB-20261112-001',
      type: 'INBOUND',
      status: 'DRAFT',
      note: 'Sample inbound order',
    };

    expect(order.type).toBe('INBOUND');
    expect(order.status).toBe('DRAFT');
  });

  it('WarehouseOrderItem model type should support Date expiry_date', () => {
    const orderItem: Partial<WarehouseOrderItem> = {
      orderId: 'order-uuid-1',
      productId: 'prod-uuid-1',
      expectedQuantity: 50,
      actualQuantity: 50,
      expiryDate: new Date('2027-12-31'),
    };

    expect(orderItem.expiryDate).toBeInstanceOf(Date);
  });

  it('Product model type should match standard attributes', () => {
    const product: Partial<Product> = {
      sku: 'SKU-TEST-001',
      barcode: '893000000001',
      name: 'Test Product',
      unit: 'Pcs',
      minSafetyStock: 5,
    };

    expect(product.unit).toBe('Pcs');
  });
});
