import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class ReceiveInventoryDto {
  @ApiProperty({
    description: 'UUID của sản phẩm',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID('all', { message: 'productId must be a valid UUID' })
  @IsNotEmpty({ message: 'productId must not be empty' })
  productId!: string;

  @ApiProperty({
    description: 'UUID của vị trí kệ kho',
    example: '660e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID('all', { message: 'locationId must be a valid UUID' })
  @IsNotEmpty({ message: 'locationId must not be empty' })
  locationId!: string;

  @ApiProperty({
    description: 'Số lượng nhập (> 0)',
    example: 50,
  })
  @IsInt({ message: 'quantity must be an integer' })
  @Min(1, { message: 'quantity must be at least 1' })
  quantity!: number;

  @ApiPropertyOptional({
    description: 'Số lô sản xuất',
    example: 'LOT-202611-01',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  lotNumber?: string;

  @ApiPropertyOptional({
    description: 'Ngày hết hạn (ISO-8601 YYYY-MM-DD)',
    example: '2027-11-22',
  })
  @IsOptional()
  @IsDateString({}, { message: 'expiryDate must be a valid ISO-8601 date string' })
  expiryDate?: string;

  @ApiPropertyOptional({
    description: 'Idempotency key cho giao dịch nhập',
    example: 'recv-key-001',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  idempotencyKey?: string;
}

export class ShipInventoryDto {
  @ApiProperty({
    description: 'UUID của sản phẩm',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID('all', { message: 'productId must be a valid UUID' })
  @IsNotEmpty({ message: 'productId must not be empty' })
  productId!: string;

  @ApiProperty({
    description: 'UUID của vị trí kệ kho',
    example: '660e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID('all', { message: 'locationId must be a valid UUID' })
  @IsNotEmpty({ message: 'locationId must not be empty' })
  locationId!: string;

  @ApiProperty({
    description: 'Số lượng xuất (> 0)',
    example: 20,
  })
  @IsInt({ message: 'quantity must be an integer' })
  @Min(1, { message: 'quantity must be at least 1' })
  quantity!: number;

  @ApiPropertyOptional({
    description: 'Số lô sản xuất (nếu chỉ định xuất theo lô cụ thể)',
    example: 'LOT-202611-01',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  lotNumber?: string;

  @ApiPropertyOptional({
    description: 'Idempotency key cho giao dịch xuất',
    example: 'ship-key-001',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  idempotencyKey?: string;
}

export class InventoryStockQueryDto {
  @ApiPropertyOptional({
    description: 'Lọc tồn kho theo UUID sản phẩm',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsOptional()
  @IsUUID('all', { message: 'productId must be a valid UUID' })
  productId?: string;

  @ApiPropertyOptional({
    description: 'Lọc tồn kho theo UUID vị trí kệ kho',
    example: '660e8400-e29b-41d4-a716-446655440001',
  })
  @IsOptional()
  @IsUUID('all', { message: 'locationId must be a valid UUID' })
  locationId?: string;
}

export class InventoryProductInfoDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() sku!: string;
  @ApiProperty() barcode!: string;
  @ApiProperty() unit!: string;
}

export class InventoryLocationInfoDto {
  @ApiProperty() id!: string;
  @ApiProperty() locationBarcode!: string;
  @ApiProperty() zoneCode!: string;
  @ApiProperty() aisleCode!: string;
  @ApiProperty() rackCode!: string;
  @ApiProperty() binCode!: string;
}

export class InventoryItemResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() productId!: string;
  @ApiProperty() locationId!: string;
  @ApiProperty() quantityOnHand!: number;
  @ApiProperty() quantityReserved!: number;
  @ApiPropertyOptional() lotNumber?: string | null;
  @ApiPropertyOptional() expiryDate?: Date | null;
  @ApiProperty() updatedAt!: Date;
  @ApiPropertyOptional({ type: InventoryProductInfoDto }) product?: InventoryProductInfoDto;
  @ApiPropertyOptional({ type: InventoryLocationInfoDto }) location?: InventoryLocationInfoDto;
}
