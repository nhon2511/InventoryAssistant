import {
  Body,
  ConflictException,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  InternalServerErrorException,
  Param,
  Post,
  Query,
  Req,
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
  ApiResponse,
  ApiTags,
  ApiUnauthorizedResponse,
  ApiUnprocessableEntityResponse,
} from '@nestjs/swagger';
import { JwtAuthenticationGuard, type AuthenticatedRequest } from '../auth/authentication.guard.js';
import { RequireTrustedRoles, TrustedRolesGuard } from '../auth/trusted-roles.guard.js';
import { OrderConfirmationService, type ConfirmationResult } from '../inventory-contract/order-confirmation.service.js';
import { ConfirmOrderDto, ConfirmOrderParamsDto, ConfirmOrderResponseDto } from './dto/confirm-order.dto.js';
import { CreateOrderDraftDto } from './dto/create-order-draft.dto.js';
import { OrderParamDto, OrderQueryDto } from './dto/order-query.dto.js';
import { OrderDetailResponseDto, OrderSummaryResponseDto } from './dto/order-response.dto.js';
import { ReviewOrderDto } from './dto/review-order.dto.js';
import { OrdersService } from './orders.service.js';

@ApiTags('Orders')
@ApiBearerAuth('JWT-auth')
@Controller('orders')
@UseGuards(JwtAuthenticationGuard, TrustedRolesGuard)
export class OrdersController {
  constructor(
    private readonly confirmationService: OrderConfirmationService,
    private readonly ordersService: OrdersService,
  ) {}

  @Get()
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({ summary: 'Tra cứu danh sách đơn hàng' })
  @ApiOkResponse({ description: 'Danh sách đơn hàng.', type: [OrderSummaryResponseDto] })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN, MANAGER hoặc STAFF.' })
  async findAll(@Query() query: OrderQueryDto): Promise<OrderSummaryResponseDto[]> {
    return this.ordersService.findAll(query);
  }

  @Get(':id')
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({ summary: 'Chi tiết đơn hàng theo UUID hoặc orderCode' })
  @ApiOkResponse({ description: 'Thông tin chi tiết đơn hàng.', type: OrderDetailResponseDto })
  @ApiNotFoundResponse({ description: 'Đơn hàng không tồn tại.' })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN, MANAGER hoặc STAFF.' })
  async findOne(@Param() params: OrderParamDto): Promise<OrderDetailResponseDto> {
    return this.ordersService.findById(params.id);
  }

  @Post('draft')
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({ summary: 'Tạo phiếu nháp nguyên tử' })
  @ApiCreatedResponse({ description: 'Phiếu nháp đã được tạo.', type: OrderDetailResponseDto })
  @ApiNotFoundResponse({ description: 'Sản phẩm hoặc vị trí không tồn tại.' })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN, MANAGER hoặc STAFF.' })
  async createDraft(
    @Body() dto: CreateOrderDraftDto,
    @Req() req: AuthenticatedRequest,
  ): Promise<OrderDetailResponseDto> {
    const actorId = req.verifiedPrincipal?.subjectId ?? null;
    return this.ordersService.createDraft(dto, actorId);
  }

  @Post(':id/review')
  @RequireTrustedRoles('ADMIN', 'MANAGER')
  @ApiOperation({ summary: 'Duyệt hoặc hủy phiếu' })
  @ApiOkResponse({ description: 'Phiếu đã được duyệt hoặc hủy.', type: OrderDetailResponseDto })
  @ApiNotFoundResponse({ description: 'Đơn hàng không tồn tại.' })
  @ApiConflictResponse({ description: 'Đơn hàng không ở trạng thái DRAFT.' })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền ADMIN hoặc MANAGER.' })
  async reviewOrder(
    @Param() params: OrderParamDto,
    @Body() dto: ReviewOrderDto,
    @Req() req: AuthenticatedRequest,
  ): Promise<OrderDetailResponseDto> {
    const actorId = req.verifiedPrincipal?.subjectId;
    if (!actorId) {
      throw new InternalServerErrorException('Principal not resolved');
    }
    return this.ordersService.reviewOrder(params.id, dto.approve, actorId);
  }

  @Post(':orderId/confirm')
  @HttpCode(HttpStatus.OK)
  @RequireTrustedRoles('ADMIN', 'MANAGER')
  @ApiOperation({
    summary: 'Xác nhận đơn hàng nhập/xuất kho',
    description:
      'Xác nhận đơn hàng DRAFT, cập nhật tồn kho và ghi sổ cái. '
      + 'Yêu cầu Bearer JWT token với vai trò ADMIN hoặc MANAGER. '
      + 'Idempotency key đảm bảo gọi trùng an toàn.',
  })
  @ApiResponse({
    status: 200,
    description: 'Đơn hàng đã được xác nhận thành công hoặc replay.',
    type: ConfirmOrderResponseDto,
  })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ hoặc hết hạn.' })
  @ApiForbiddenResponse({ description: 'Vai trò không đủ quyền (cần ADMIN hoặc MANAGER).' })
  @ApiNotFoundResponse({ description: 'Đơn hàng không tồn tại.' })
  @ApiConflictResponse({ description: 'Idempotency key đã được dùng với nội dung khác.' })
  @ApiUnprocessableEntityResponse({ description: 'Đơn hàng không ở trạng thái DRAFT hoặc dữ liệu không hợp lệ.' })
  async confirm(
    @Param() params: ConfirmOrderParamsDto,
    @Body() body: ConfirmOrderDto,
    @Req() req: AuthenticatedRequest,
  ): Promise<ConfirmOrderResponseDto> {
    const principal = req.verifiedPrincipal;
    if (!principal) {
      throw new InternalServerErrorException('Principal not resolved');
    }

    // Build a minimal bearer token string from the original request
    // to pass to the service (which re-verifies it internally).
    const authHeader = req.headers.authorization;
    const token = typeof authHeader === 'string'
      ? authHeader.replace(/^Bearer\s+/i, '')
      : '';

    let result: ConfirmationResult;
    try {
      result = await this.confirmationService.confirm(token, {
        orderId: params.orderId,
        type: body.type,
        idempotencyKey: body.idempotencyKey,
      });
    } catch (error) {
      // Map domain errors to HTTP status codes.
      const message = error instanceof Error ? error.message : 'Confirmation failed';
      if (message.includes('Order not found') || message.includes('ownership mismatch')) {
        throw new ConflictException(message);
      }
      if (message.includes('cannot be confirmed') || message.includes('Invalid') ||
          message.includes('no lines') || message.includes('Missing or ambiguous') ||
          message.includes('identity mismatch') || message.includes('Insufficient')) {
        throw new ConflictException(message);
      }
      throw new InternalServerErrorException('Order confirmation failed');
    }

    switch (result.kind) {
      case 'conflict':
        throw new ConflictException('Idempotency key conflict: same key used with different request');
      case 'in_progress':
        throw new ConflictException('Confirmation already in progress');
      case 'expired':
        throw new ConflictException('Idempotency key has expired');
      case 'applied':
      case 'replay':
        return {
          kind: result.kind,
          orderId: result.orderId,
          movements: result.movements,
        };
    }
  }
}
