import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class QueryStockRequestDto {
  @ApiPropertyOptional({ description: 'Tên sản phẩm cần tra cứu', example: 'Mì Hảo Hảo' })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  product_name?: string;

  @ApiPropertyOptional({ description: 'Mã vị trí kệ', example: 'A1' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  location?: string;

  @ApiPropertyOptional({ description: 'Mã SKU sản phẩm', example: 'SKU-001' })
  @IsOptional()
  @IsString()
  @MaxLength(100)
  sku?: string;
}

export class QueryStockResponseDto {
  @ApiProperty({
    description: 'Câu trả lời tự nhiên về tồn kho',
    example: 'Hiện tại kệ A1 còn 350 hộp Mì Hảo Hảo.',
  })
  answer!: string;

  @ApiPropertyOptional({
    description: 'Danh sách kết quả tồn kho chi tiết',
  })
  items?: Array<{
    productName: string;
    sku: string;
    location: string;
    quantity: number;
    unit: string;
  }>;
}
