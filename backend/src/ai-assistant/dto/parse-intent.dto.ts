import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class ParseIntentRequestDto {
  @ApiProperty({
    description: 'Câu nói / văn bản tiếng Việt từ người dùng',
    example: 'Còn bao nhiêu hộp Mì Hảo Hảo ở kệ A1?',
  })
  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  text!: string;
}

export class ParseIntentResponseDto {
  @ApiProperty({
    description: 'Ý định: query_stock | create_order | report | unknown',
    example: 'query_stock',
  })
  intent!: string;

  @ApiProperty({
    description: 'Điểm tin cậy từ 0.0 đến 1.0',
    example: 0.94,
  })
  confidence!: number;

  @ApiPropertyOptional({
    description: 'Các thực thể bóc tách được',
    example: { product_name: 'Mì Hảo Hảo', location: 'A1', quantity: '100', unit: 'hộp' },
  })
  entities!: Record<string, string>;
}
