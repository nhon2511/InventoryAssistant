import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  ArrayMinSize,
  IsArray,
  IsDateString,
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
  ValidateNested,
} from 'class-validator';
import { OrderTypeEnum } from './order-query.dto.js';

export class CreateOrderItemDraftDto {
  @ApiProperty({
    description: 'UUID của sản phẩm',
    example: '550e8400-e29b-41d4-a716-446655440001',
  })
  @IsUUID('all', { message: 'productId must be a valid UUID' })
  @IsNotEmpty({ message: 'productId must not be empty' })
  productId!: string;

  @ApiPropertyOptional({
    description: 'UUID vị trí kệ kho (tùy chọn khi tạo nháp)',
    example: '660e8400-e29b-41d4-a716-446655440001',
  })
  @IsOptional()
  @IsUUID('all', { message: 'locationId must be a valid UUID' })
  locationId?: string;

  @ApiProperty({
    description: 'Số lượng dự kiến (> 0)',
    example: 100,
  })
  @IsInt({ message: 'expectedQuantity must be an integer' })
  @Min(1, { message: 'expectedQuantity must be at least 1' })
  expectedQuantity!: number;

  @ApiPropertyOptional({
    description: 'Số lô sản xuất',
    example: 'LOT-202611-A',
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
}

export class CreateOrderDraftDto {
  @ApiProperty({
    description: 'Loại đơn hàng: INBOUND hoặc OUTBOUND',
    enum: OrderTypeEnum,
    example: 'INBOUND',
  })
  @IsEnum(OrderTypeEnum, { message: 'type must be INBOUND or OUTBOUND' })
  type!: OrderTypeEnum;

  @ApiPropertyOptional({
    description: 'Ghi chú đơn hàng',
    example: 'Nhập hàng từ nhà cung cấp ACECOOK',
  })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;

  @ApiPropertyOptional({
    description: 'Idempotency key hoặc mã request từ client',
    example: 'req-draft-001',
  })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  requestId?: string;

  @ApiProperty({
    description: 'Danh sách các dòng hàng trong phiếu nháp',
    type: [CreateOrderItemDraftDto],
  })
  @IsArray()
  @ArrayMinSize(1, { message: 'items must contain at least 1 item' })
  @ValidateNested({ each: true })
  @Type(() => CreateOrderItemDraftDto)
  items!: CreateOrderItemDraftDto[];
}
