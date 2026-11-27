import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export enum DraftOrderTypeEnum {
  INBOUND = 'INBOUND',
  OUTBOUND = 'OUTBOUND',
}

export class AiCreateDraftRequestDto {
  @ApiProperty({
    description: 'Loại phiếu: INBOUND hoặc OUTBOUND',
    enum: DraftOrderTypeEnum,
    example: 'INBOUND',
  })
  @IsEnum(DraftOrderTypeEnum)
  type!: DraftOrderTypeEnum;

  @ApiPropertyOptional({ description: 'Tên sản phẩm', example: 'Mì Hảo Hảo' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  product_name?: string;

  @ApiPropertyOptional({ description: 'Mã vị trí kệ', example: 'A1' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @ApiPropertyOptional({ description: 'Số lượng (string từ NLU)', example: '100' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  quantity?: string;

  @ApiPropertyOptional({ description: 'Đơn vị tính', example: 'hộp' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  unit?: string;

  @ApiPropertyOptional({ description: 'Ghi chú bổ sung', example: 'Nhập từ nhà cung cấp ACECOOK' })
  @IsOptional()
  @IsString()
  @MaxLength(1000)
  note?: string;
}

export class AiCreateDraftResponseDto {
  @ApiProperty({ description: 'Thông báo cho người dùng' })
  message!: string;

  @ApiPropertyOptional({ description: 'Phiếu nháp vừa tạo (nếu đủ thông tin)' })
  draft?: Record<string, unknown>;

  @ApiProperty({ description: 'Có cần người dùng xác nhận hay bổ sung thêm không?' })
  requiresConfirmation!: boolean;

  @ApiPropertyOptional({ description: 'Thông tin còn thiếu cần người dùng bổ sung' })
  missingFields?: string[];
}
