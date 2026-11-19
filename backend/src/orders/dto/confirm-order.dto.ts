import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsEnum,
  IsNotEmpty,
  IsString,
  IsUUID,
  MaxLength,
  MinLength,
} from 'class-validator';

export enum ConfirmationTypeDto {
  INBOUND = 'INBOUND',
  OUTBOUND = 'OUTBOUND',
}

export class ConfirmOrderDto {
  @ApiProperty({
    description: 'Loại xác nhận: INBOUND (nhập kho) hoặc OUTBOUND (xuất kho)',
    enum: ConfirmationTypeDto,
    example: 'INBOUND',
  })
  @IsEnum(ConfirmationTypeDto, {
    message: 'type must be INBOUND or OUTBOUND',
  })
  type!: ConfirmationTypeDto;

  @ApiProperty({
    description:
      'Idempotency key đảm bảo yêu cầu không bị xử lý trùng lặp. '
      + 'Client tạo UUID v4 duy nhất cho mỗi lần xác nhận.',
    example: '550e8400-e29b-41d4-a716-446655440000',
    minLength: 1,
    maxLength: 200,
  })
  @IsString()
  @IsNotEmpty({ message: 'idempotencyKey must not be empty' })
  @MinLength(1)
  @MaxLength(200)
  idempotencyKey!: string;
}

export class ConfirmOrderParamsDto {
  @ApiProperty({
    description: 'UUID của đơn hàng cần xác nhận',
    example: '550e8400-e29b-41d4-a716-446655440000',
  })
  @IsUUID('all', { message: 'orderId must be a valid UUID' })
  orderId!: string;
}

export class ConfirmOrderResponseDto {
  @ApiProperty({ description: 'Kết quả xác nhận', example: 'applied' })
  kind!: string;

  @ApiPropertyOptional({ description: 'UUID đơn hàng đã xác nhận' })
  orderId?: string;

  @ApiPropertyOptional({ description: 'Số lượng dòng hàng đã xử lý' })
  movements?: number;
}
