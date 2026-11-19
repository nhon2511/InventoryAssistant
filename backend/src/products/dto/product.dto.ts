import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateProductDto {
  @ApiProperty({ description: 'Tên sản phẩm', example: 'Mì Hảo Hảo' })
  @IsString()
  @IsNotEmpty({ message: 'name must not be empty' })
  @MaxLength(500)
  name!: string;

  @ApiProperty({ description: 'Mã SKU duy nhất', example: 'SKU-MHH-001' })
  @IsString()
  @IsNotEmpty({ message: 'sku must not be empty' })
  @MaxLength(100)
  sku!: string;

  @ApiProperty({ description: 'Mã vạch duy nhất', example: '8934563118020' })
  @IsString()
  @IsNotEmpty({ message: 'barcode must not be empty' })
  @MaxLength(200)
  barcode!: string;

  @ApiPropertyOptional({ description: 'Đơn vị tính', example: 'Thùng', default: 'Pcs' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  unit?: string;

  @ApiPropertyOptional({ description: 'Mô tả sản phẩm', example: 'Mì ăn liền hương tôm chua cay' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ description: 'Mức tồn kho an toàn tối thiểu', example: 100, default: 0 })
  @IsOptional()
  @IsInt({ message: 'minSafetyStock must be an integer' })
  @Min(0, { message: 'minSafetyStock must not be negative' })
  minSafetyStock?: number;
}

export class UpdateProductDto {
  @ApiPropertyOptional({ description: 'Tên sản phẩm', example: 'Mì Hảo Hảo Tôm Chua Cay' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'name must not be empty' })
  @MaxLength(500)
  name?: string;

  @ApiPropertyOptional({ description: 'Mã SKU duy nhất', example: 'SKU-MHH-002' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'sku must not be empty' })
  @MaxLength(100)
  sku?: string;

  @ApiPropertyOptional({ description: 'Mã vạch duy nhất', example: '8934563118037' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'barcode must not be empty' })
  @MaxLength(200)
  barcode?: string;

  @ApiPropertyOptional({ description: 'Đơn vị tính', example: 'Thùng' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  unit?: string;

  @ApiPropertyOptional({ description: 'Mô tả sản phẩm' })
  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @ApiPropertyOptional({ description: 'Mức tồn kho an toàn tối thiểu', example: 50 })
  @IsOptional()
  @IsInt({ message: 'minSafetyStock must be an integer' })
  @Min(0, { message: 'minSafetyStock must not be negative' })
  minSafetyStock?: number;
}

export class ProductResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() sku!: string;
  @ApiProperty() barcode!: string;
  @ApiProperty() unit!: string;
  @ApiPropertyOptional() description?: string | null;
  @ApiProperty() minSafetyStock!: number;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
}

export class ProductParamsDto {
  @ApiProperty({ description: 'UUID hoặc barcode của sản phẩm' })
  @IsString()
  @IsNotEmpty()
  id!: string;
}
