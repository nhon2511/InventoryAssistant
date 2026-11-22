import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty } from 'class-validator';

export class ReviewOrderDto {
  @ApiProperty({
    description: 'true: Duyệt phiếu (chuyển sang CONFIRMED), false: Hủy phiếu (chuyển sang CANCELLED)',
    example: true,
  })
  @IsBoolean({ message: 'approve must be a boolean' })
  @IsNotEmpty({ message: 'approve must not be empty' })
  approve!: boolean;
}
