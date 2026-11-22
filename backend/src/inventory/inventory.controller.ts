import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiNotFoundResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { JwtAuthenticationGuard } from '../auth/authentication.guard.js';
import { RequireTrustedRoles, TrustedRolesGuard } from '../auth/trusted-roles.guard.js';
import {
  InventoryItemResponseDto,
  InventoryStockQueryDto,
  ReceiveInventoryDto,
  ShipInventoryDto,
} from './dto/inventory-movement.dto.js';
import { InventoryService } from './inventory.service.js';

@ApiTags('Inventory')
@ApiBearerAuth('JWT-auth')
@Controller('inventory')
@UseGuards(JwtAuthenticationGuard, TrustedRolesGuard)
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Post('receive')
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({ summary: 'Nhập hàng trực tiếp vào vị trí kho' })
  @ApiCreatedResponse({ description: 'Đã nhập hàng thành công.', type: InventoryItemResponseDto })
  @ApiNotFoundResponse({ description: 'Sản phẩm hoặc vị trí không tồn tại.' })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN, MANAGER hoặc STAFF.' })
  async receive(@Body() dto: ReceiveInventoryDto): Promise<InventoryItemResponseDto> {
    return this.inventoryService.receive(dto);
  }

  @Post('ship')
  @HttpCode(HttpStatus.OK)
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({ summary: 'Xuất hàng trực tiếp từ vị trí kho' })
  @ApiOkResponse({ description: 'Đã xuất hàng thành công.', type: InventoryItemResponseDto })
  @ApiNotFoundResponse({ description: 'Không tìm thấy tồn kho cho sản phẩm tại vị trí.' })
  @ApiUnprocessableEntityResponse({ description: 'Tồn khả dụng không đủ để xuất.' })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN, MANAGER hoặc STAFF.' })
  async ship(@Body() dto: ShipInventoryDto): Promise<InventoryItemResponseDto> {
    return this.inventoryService.ship(dto);
  }

  @Get('stock')
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({ summary: 'Tra cứu tồn kho tổng hợp theo productId hoặc locationId' })
  @ApiOkResponse({ description: 'Danh sách tồn kho.', type: [InventoryItemResponseDto] })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN, MANAGER hoặc STAFF.' })
  async getStock(@Query() query: InventoryStockQueryDto): Promise<InventoryItemResponseDto[]> {
    return this.inventoryService.getStock(query);
  }
}
