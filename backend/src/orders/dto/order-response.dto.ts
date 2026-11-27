import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class OrderCountDto {
  @ApiProperty({ description: 'Số lượng dòng hàng', example: 5 })
  items!: number;
}

export class OrderItemProductDto {
  @ApiProperty() id!: string;
  @ApiProperty() name!: string;
  @ApiProperty() sku!: string;
  @ApiProperty() barcode!: string;
  @ApiProperty() unit!: string;
}

export class OrderItemLocationDto {
  @ApiProperty() id!: string;
  @ApiProperty() locationBarcode!: string;
  @ApiProperty() zoneCode!: string;
  @ApiProperty() aisleCode!: string;
  @ApiProperty() rackCode!: string;
  @ApiProperty() binCode!: string;
}

export class OrderItemDetailDto {
  @ApiProperty() id!: string;
  @ApiProperty() orderId!: string;
  @ApiProperty() productId!: string;
  @ApiPropertyOptional() locationId?: string | null;
  @ApiProperty() expectedQuantity!: number;
  @ApiProperty() actualQuantity!: number;
  @ApiPropertyOptional() lotNumber?: string | null;
  @ApiPropertyOptional() expiryDate?: Date | null;
  @ApiProperty() createdAt!: Date;
  @ApiPropertyOptional({ type: OrderItemProductDto }) product?: OrderItemProductDto;
  @ApiPropertyOptional({ type: OrderItemLocationDto }) location?: OrderItemLocationDto | null;
}

export class OrderSummaryResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() orderCode!: string;
  @ApiProperty() type!: string;
  @ApiProperty() status!: string;
  @ApiPropertyOptional() createdBy?: string | null;
  @ApiPropertyOptional() approvedBy?: string | null;
  @ApiPropertyOptional() note?: string | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiProperty({ type: OrderCountDto }) _count!: OrderCountDto;
  @ApiProperty({ type: [OrderItemDetailDto] }) items!: OrderItemDetailDto[];
}

export class OrderDetailResponseDto {
  @ApiProperty() id!: string;
  @ApiProperty() orderCode!: string;
  @ApiProperty() type!: string;
  @ApiProperty() status!: string;
  @ApiPropertyOptional() createdBy?: string | null;
  @ApiPropertyOptional() approvedBy?: string | null;
  @ApiPropertyOptional() note?: string | null;
  @ApiProperty() createdAt!: Date;
  @ApiProperty() updatedAt!: Date;
  @ApiProperty({ type: [OrderItemDetailDto] }) items!: OrderItemDetailDto[];
}
