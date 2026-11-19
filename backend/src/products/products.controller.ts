import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiConflictResponse,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JwtAuthenticationGuard } from '../auth/authentication.guard.js';
import { RequireTrustedRoles, TrustedRolesGuard } from '../auth/trusted-roles.guard.js';
import {
  CreateProductDto,
  ProductParamsDto,
  ProductResponseDto,
  UpdateProductDto,
} from './dto/product.dto.js';
import { ProductsService } from './products.service.js';

@ApiTags('Products')
@ApiBearerAuth('JWT-auth')
@Controller('products')
@UseGuards(JwtAuthenticationGuard)
export class ProductsController {
  constructor(private readonly productsService: ProductsService) {}

  @Get()
  @ApiOperation({ summary: 'Danh sách tất cả sản phẩm' })
  @ApiOkResponse({ description: 'Danh sách sản phẩm.', type: [ProductResponseDto] })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  async findAll(): Promise<ProductResponseDto[]> {
    return this.productsService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Chi tiết sản phẩm theo UUID hoặc barcode' })
  @ApiOkResponse({ description: 'Thông tin sản phẩm.', type: ProductResponseDto })
  @ApiNotFoundResponse({ description: 'Sản phẩm không tồn tại.' })
  async findOne(@Param() params: ProductParamsDto): Promise<ProductResponseDto> {
    return this.productsService.findById(params.id);
  }

  @Post()
  @UseGuards(TrustedRolesGuard)
  @RequireTrustedRoles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Tạo sản phẩm mới' })
  @ApiCreatedResponse({ description: 'Sản phẩm đã được tạo.', type: ProductResponseDto })
  @ApiConflictResponse({ description: 'SKU hoặc barcode đã tồn tại.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN hoặc MANAGER.' })
  async create(@Body() dto: CreateProductDto): Promise<ProductResponseDto> {
    return this.productsService.create(dto);
  }

  @Put(':id')
  @UseGuards(TrustedRolesGuard)
  @RequireTrustedRoles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Cập nhật sản phẩm' })
  @ApiOkResponse({ description: 'Sản phẩm đã được cập nhật.', type: ProductResponseDto })
  @ApiNotFoundResponse({ description: 'Sản phẩm không tồn tại.' })
  @ApiConflictResponse({ description: 'SKU hoặc barcode trùng.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN hoặc MANAGER.' })
  async update(
    @Param() params: ProductParamsDto,
    @Body() dto: UpdateProductDto,
  ): Promise<ProductResponseDto> {
    return this.productsService.update(params.id, dto);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  @UseGuards(TrustedRolesGuard)
  @RequireTrustedRoles('ADMIN')
  @ApiOperation({ summary: 'Xóa sản phẩm (chỉ khi không có tham chiếu)' })
  @ApiOkResponse({ description: 'Sản phẩm đã bị xóa.' })
  @ApiNotFoundResponse({ description: 'Sản phẩm không tồn tại.' })
  @ApiConflictResponse({ description: 'Sản phẩm đang có tồn kho hoặc phiếu tham chiếu.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN.' })
  async remove(@Param() params: ProductParamsDto): Promise<void> {
    await this.productsService.remove(params.id);
  }
}
