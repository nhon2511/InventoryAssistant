import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Req,
  UseGuards,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiCreatedResponse,
  ApiForbiddenResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from '@nestjs/swagger';
import { JwtAuthenticationGuard, type AuthenticatedRequest } from '../auth/authentication.guard.js';
import { RequireTrustedRoles, TrustedRolesGuard } from '../auth/trusted-roles.guard.js';
import { AiAssistantService } from './ai-assistant.service.js';
import { ParseIntentRequestDto, ParseIntentResponseDto } from './dto/parse-intent.dto.js';
import { QueryStockRequestDto, QueryStockResponseDto } from './dto/query-stock.dto.js';
import { AiCreateDraftRequestDto, AiCreateDraftResponseDto } from './dto/create-draft.dto.js';

@ApiTags('AI Assistant')
@ApiBearerAuth('JWT-auth')
@Controller('ai')
@UseGuards(JwtAuthenticationGuard, TrustedRolesGuard)
export class AiAssistantController {
  constructor(private readonly service: AiAssistantService) {}

  @Post('parse-intent')
  @HttpCode(HttpStatus.OK)
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({
    summary: 'Phân tích ý định từ văn bản tiếng Việt',
    description: 'Gọi Gemini API để bóc tách intent, confidence và entities từ câu nói của nhân viên kho.',
  })
  @ApiOkResponse({ description: 'Kết quả phân tích ý định.', type: ParseIntentResponseDto })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền STAFF trở lên.' })
  async parseIntent(@Body() dto: ParseIntentRequestDto): Promise<ParseIntentResponseDto> {
    return this.service.parseIntent(dto.text);
  }

  @Post('query-stock')
  @HttpCode(HttpStatus.OK)
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({
    summary: 'Tra cứu tồn kho thực tế và sinh câu trả lời tự nhiên',
    description: 'Truy vấn database và dùng Gemini tạo câu trả lời tiếng Việt tự nhiên.',
  })
  @ApiOkResponse({ description: 'Kết quả tồn kho và câu trả lời tự nhiên.', type: QueryStockResponseDto })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền STAFF trở lên.' })
  async queryStock(@Body() dto: QueryStockRequestDto): Promise<QueryStockResponseDto> {
    return this.service.queryStock(dto);
  }

  @Post('create-draft')
  @RequireTrustedRoles('ADMIN', 'MANAGER', 'STAFF')
  @ApiOperation({
    summary: 'Tạo phiếu nhập/xuất kho nháp từ dữ liệu NLU',
    description: 'Nhận entities từ parse-intent, tìm sản phẩm và vị trí trong DB, tạo phiếu nháp để người dùng xác nhận (Human-in-the-loop).',
  })
  @ApiCreatedResponse({ description: 'Phiếu nháp đã được tạo hoặc yêu cầu thêm thông tin.', type: AiCreateDraftResponseDto })
  @ApiUnauthorizedResponse({ description: 'Token không hợp lệ.' })
  @ApiForbiddenResponse({ description: 'Cần quyền STAFF trở lên.' })
  async createDraft(
    @Body() dto: AiCreateDraftRequestDto,
    @Req() req: AuthenticatedRequest,
  ): Promise<AiCreateDraftResponseDto> {
    const actorId = req.verifiedPrincipal?.subjectId ?? null;
    return this.service.createDraftOrder(dto, actorId);
  }
}
