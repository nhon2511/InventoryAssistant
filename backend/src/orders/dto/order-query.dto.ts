import { ApiPropertyOptional, ApiProperty } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';

export enum OrderTypeEnum {
  INBOUND = 'INBOUND',
  OUTBOUND = 'OUTBOUND',
}

export enum OrderStatusEnum {
  DRAFT = 'DRAFT',
  CONFIRMED = 'CONFIRMED',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export class OrderQueryDto {
  @ApiPropertyOptional({
    description: 'Loại đơn hàng: INBOUND hoặc OUTBOUND',
    enum: OrderTypeEnum,
  })
  @IsOptional()
  @IsEnum(OrderTypeEnum, { message: 'type must be INBOUND or OUTBOUND' })
  type?: OrderTypeEnum;

  @ApiPropertyOptional({
    description: 'Trạng thái đơn hàng',
    enum: OrderStatusEnum,
  })
  @IsOptional()
  @IsEnum(OrderStatusEnum, {
    message: 'status must be DRAFT, CONFIRMED, COMPLETED, or CANCELLED',
  })
  status?: OrderStatusEnum;

  @ApiPropertyOptional({
    description: 'UUID của người tạo đơn',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsOptional()
  @IsUUID('all', { message: 'createdBy must be a valid UUID' })
  createdBy?: string;

  @ApiPropertyOptional({
    description: 'Từ khóa tìm kiếm theo mã đơn hoặc ghi chú',
    example: 'INB-2026',
  })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  search?: string;
}

export class OrderParamDto {
  @ApiProperty({
    description: 'UUID hoặc mã đơn hàng (orderCode)',
    example: 'INB-202611-0001',
  })
  @IsString()
  @IsNotEmpty({ message: 'id must not be empty' })
  id!: string;
}
