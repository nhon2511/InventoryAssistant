import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Prisma } from '@prisma/client';
import {
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateLocationDto {
  @ApiProperty({ description: 'Mã khu vực (Zone)', example: 'Z-A' })
  @IsString()
  @IsNotEmpty({ message: 'zoneCode must not be empty' })
  @MaxLength(50)
  zoneCode!: string;

  @ApiProperty({ description: 'Mã dãy (Aisle)', example: 'A-01' })
  @IsString()
  @IsNotEmpty({ message: 'aisleCode must not be empty' })
  @MaxLength(50)
  aisleCode!: string;

  @ApiProperty({ description: 'Mã kệ (Rack)', example: 'R-01' })
  @IsString()
  @IsNotEmpty({ message: 'rackCode must not be empty' })
  @MaxLength(50)
  rackCode!: string;

  @ApiProperty({ description: 'Mã ô/ngăn (Bin)', example: 'B-01' })
  @IsString()
  @IsNotEmpty({ message: 'binCode must not be empty' })
  @MaxLength(50)
  binCode!: string;

  @ApiProperty({ description: 'Mã vạch vị trí duy nhất', example: 'LOC-ZA-A01-R01-B01' })
  @IsString()
  @IsNotEmpty({ message: 'locationBarcode must not be empty' })
  @MaxLength(100)
  locationBarcode!: string;

  @ApiPropertyOptional({ description: 'Tải trọng tối đa (kg)', example: 500.0 })
  @IsOptional()
  @IsNumber({}, { message: 'maxCapacityKg must be a valid number' })
  @Min(0, { message: 'maxCapacityKg must not be negative' })
  maxCapacityKg?: number;
}

export class UpdateLocationDto {
  @ApiPropertyOptional({ description: 'Mã khu vực (Zone)', example: 'Z-B' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'zoneCode must not be empty' })
  @MaxLength(50)
  zoneCode?: string;

  @ApiPropertyOptional({ description: 'Mã dãy (Aisle)', example: 'A-02' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'aisleCode must not be empty' })
  @MaxLength(50)
  aisleCode?: string;

  @ApiPropertyOptional({ description: 'Mã kệ (Rack)', example: 'R-02' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'rackCode must not be empty' })
  @MaxLength(50)
  rackCode?: string;

  @ApiPropertyOptional({ description: 'Mã ô/ngăn (Bin)', example: 'B-02' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'binCode must not be empty' })
  @MaxLength(50)
  binCode?: string;

  @ApiPropertyOptional({ description: 'Mã vạch vị trí duy nhất', example: 'LOC-ZB-A02-R02-B02' })
  @IsOptional()
  @IsString()
  @IsNotEmpty({ message: 'locationBarcode must not be empty' })
  @MaxLength(100)
  locationBarcode?: string;

  @ApiPropertyOptional({ description: 'Tải trọng tối đa (kg)', example: 1000.0 })
  @IsOptional()
  @IsNumber({}, { message: 'maxCapacityKg must be a valid number' })
  @Min(0, { message: 'maxCapacityKg must not be negative' })
  maxCapacityKg?: number;
}

export class LocationResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() zoneCode!: string;
  @ApiProperty() aisleCode!: string;
  @ApiProperty() rackCode!: string;
  @ApiProperty() binCode!: string;
  @ApiProperty() locationBarcode!: string;
  @ApiPropertyOptional({ type: Number }) maxCapacityKg?: Prisma.Decimal | number | string | null;
  @ApiProperty() createdAt!: Date;
}

export class LocationParamsDto {
  @ApiProperty({ description: 'UUID hoặc locationBarcode của vị trí' })
  @IsString()
  @IsNotEmpty()
  id!: string;
}
