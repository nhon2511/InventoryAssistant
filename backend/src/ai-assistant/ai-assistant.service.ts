import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenAI } from '@google/genai';
import { PrismaService } from '../prisma/prisma.service.js';
import type { ParseIntentResponseDto } from './dto/parse-intent.dto.js';
import type { QueryStockResponseDto, QueryStockRequestDto } from './dto/query-stock.dto.js';
import type { AiCreateDraftRequestDto, AiCreateDraftResponseDto } from './dto/create-draft.dto.js';

const PARSE_INTENT_SYSTEM_PROMPT = `Bạn là hệ thống NLU (Natural Language Understanding) cho ứng dụng quản lý kho hàng thông minh Smart WMS.
Nhiệm vụ: Phân tích câu tiếng Việt từ nhân viên kho và trả về JSON với đúng 3 trường sau:

{
  "intent": "<một trong các giá trị: query_stock | create_order | report | unknown>",
  "confidence": <số thực từ 0.0 đến 1.0>,
  "entities": {
    "product_name": "<tên sản phẩm nếu có, hoặc bỏ qua trường này>",
    "sku": "<mã SKU nếu có, hoặc bỏ qua>",
    "location": "<mã vị trí kệ nếu có, hoặc bỏ qua>",
    "quantity": "<số lượng dạng chuỗi nếu có, hoặc bỏ qua>",
    "unit": "<đơn vị tính nếu có, hoặc bỏ qua>",
    "type": "<INBOUND hoặc OUTBOUND nếu có, hoặc bỏ qua>"
  }
}

Quy tắc phân loại intent:
- "query_stock": hỏi về số lượng tồn kho, vị trí hàng, kiểm tra còn hàng không
- "create_order": tạo phiếu nhập kho (INBOUND) hoặc xuất kho (OUTBOUND), lấy hàng, nhập hàng
- "report": xem báo cáo, thống kê, lịch sử
- "unknown": không thuộc các loại trên

Chỉ trả về JSON thuần túy, không có markdown, không có giải thích thêm.`;

@Injectable()
export class AiAssistantService {
  private readonly logger = new Logger(AiAssistantService.name);
  private readonly genai: GoogleGenAI;
  private readonly model = 'gemini-2.5-flash';

  constructor(
    private readonly config: ConfigService,
    private readonly prisma: PrismaService,
  ) {
    const apiKey = this.config.get<string>('GEMINI_API_KEY');
    if (!apiKey) {
      throw new Error('GEMINI_API_KEY is not configured');
    }
    this.genai = new GoogleGenAI({ apiKey });
  }

  // ─── 1. Parse Intent ──────────────────────────────────────────────────────

  async parseIntent(text: string): Promise<ParseIntentResponseDto> {
    try {
      const response = await this.genai.models.generateContent({
        model: this.model,
        contents: [
          { role: 'user', parts: [{ text }] },
        ],
        config: {
          systemInstruction: PARSE_INTENT_SYSTEM_PROMPT,
          responseMimeType: 'application/json',
          temperature: 0.1,
        },
      });

      const raw = response.text ?? '{}';
      const parsed = JSON.parse(raw) as {
        intent?: string;
        confidence?: number;
        entities?: Record<string, string>;
      };

      return {
        intent: parsed.intent ?? 'unknown',
        confidence: parsed.confidence ?? 0.0,
        entities: parsed.entities ?? {},
      };
    } catch (error) {
      this.logger.error('parseIntent failed', error);
      return { intent: 'unknown', confidence: 0.0, entities: {} };
    }
  }

  // ─── 2. Query Stock ───────────────────────────────────────────────────────

  async queryStock(query: QueryStockRequestDto): Promise<QueryStockResponseDto> {
    try {
      // Truy vấn DB thực tế: fuzzy search theo tên sản phẩm / SKU / vị trí
      const items = await this.prisma.$queryRaw<
        Array<{
          productName: string;
          sku: string;
          location: string;
          quantity: bigint;
          unit: string;
        }>
      >`
        SELECT
          p.name        AS "productName",
          p.sku         AS sku,
          l."locationBarcode" AS location,
          COALESCE(ii.quantity, 0) AS quantity,
          COALESCE(p.unit, 'cái')  AS unit
        FROM "Product" p
        LEFT JOIN "InventoryItem" ii ON ii."productId" = p.id
        LEFT JOIN "Location"  l  ON l.id = ii."locationId"
        WHERE
          (
            ${query.product_name ? query.product_name : null}::text IS NULL
            OR p.name ILIKE ${'%' + (query.product_name ?? '') + '%'}
            OR p.sku  ILIKE ${'%' + (query.product_name ?? '') + '%'}
          )
          AND (
            ${query.sku ? query.sku : null}::text IS NULL
            OR p.sku ILIKE ${'%' + (query.sku ?? '') + '%'}
          )
          AND (
            ${query.location ? query.location : null}::text IS NULL
            OR l."locationBarcode" ILIKE ${'%' + (query.location ?? '') + '%'}
            OR l."zoneCode"        ILIKE ${'%' + (query.location ?? '') + '%'}
          )
        ORDER BY p.name, l."locationBarcode"
        LIMIT 20
      `;

      const mapped = items.map((r) => ({
        productName: r.productName,
        sku: r.sku,
        location: r.location ?? '—',
        quantity: Number(r.quantity),
        unit: r.unit,
      }));

      // Sinh câu trả lời tự nhiên qua Gemini
      const dataContext = mapped.length > 0
        ? mapped.map((i) =>
            `${i.productName} (SKU: ${i.sku}) tại kệ ${i.location}: ${i.quantity} ${i.unit}`
          ).join('\n')
        : 'Không tìm thấy sản phẩm nào phù hợp.';

      const answerPrompt = `Dựa trên dữ liệu tồn kho thực tế dưới đây, hãy trả lời ngắn gọn, tự nhiên bằng tiếng Việt cho nhân viên kho:

Dữ liệu:
${dataContext}

Câu hỏi ban đầu: tra cứu tồn kho${query.product_name ? ` "${query.product_name}"` : ''}${query.location ? ` tại kệ "${query.location}"` : ''}.

Chỉ trả về câu trả lời dạng văn bản thuần, không có markdown.`;

      const answerResp = await this.genai.models.generateContent({
        model: this.model,
        contents: [{ role: 'user', parts: [{ text: answerPrompt }] }],
        config: { temperature: 0.3 },
      });

      return {
        answer: answerResp.text?.trim() ?? dataContext,
        items: mapped,
      };
    } catch (error) {
      this.logger.error('queryStock failed', error);
      return { answer: 'Có lỗi xảy ra khi truy vấn tồn kho. Vui lòng thử lại.', items: [] };
    }
  }

  // ─── 3. Create Draft Order ────────────────────────────────────────────────

  async createDraftOrder(
    dto: AiCreateDraftRequestDto,
    actorId: string | null,
  ): Promise<AiCreateDraftResponseDto> {
    const missingFields: string[] = [];

    if (!dto.product_name && !dto.location) missingFields.push('product_name');
    const qty = dto.quantity ? parseInt(dto.quantity, 10) : NaN;
    if (!dto.quantity || isNaN(qty) || qty <= 0) missingFields.push('quantity');

    if (missingFields.length > 0) {
      return {
        message: `Để tạo phiếu ${dto.type === 'INBOUND' ? 'nhập' : 'xuất'} kho, bạn cần cung cấp thêm: ${missingFields.join(', ')}.`,
        requiresConfirmation: false,
        missingFields,
      };
    }

    try {
      // Tìm product theo tên (fuzzy)
      const products = await this.prisma.product.findMany({
        where: { name: { contains: dto.product_name!, mode: 'insensitive' } },
        take: 1,
        select: { id: true, name: true, sku: true, unit: true },
      });

      if (products.length === 0) {
        return {
          message: `Không tìm thấy sản phẩm "${dto.product_name}" trong hệ thống.`,
          requiresConfirmation: false,
          missingFields: ['product_name'],
        };
      }
      const product = products[0];

      // Tìm location nếu có
      let locationId: string | undefined;
      if (dto.location) {
        const loc = await this.prisma.location.findFirst({
          where: {
            OR: [
              { locationBarcode: { contains: dto.location, mode: 'insensitive' } },
              { zoneCode: { contains: dto.location, mode: 'insensitive' } },
            ],
          },
          select: { id: true, locationBarcode: true },
        });
        if (loc) locationId = loc.id;
      }

      // Tạo phiếu nháp qua Prisma
      const now = new Date();
      const prefix = `${dto.type === 'INBOUND' ? 'AI-INB' : 'AI-OUTB'}-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}`;
      const lastOrder = await this.prisma.warehouseOrder.findFirst({
        where: { orderCode: { startsWith: prefix } },
        orderBy: { orderCode: 'desc' },
        select: { orderCode: true },
      });
      let nextSeq = 1;
      if (lastOrder) {
        const parts = lastOrder.orderCode.split('-');
        const last = parseInt(parts[parts.length - 1], 10);
        if (!isNaN(last)) nextSeq = last + 1;
      }
      const orderCode = `${prefix}-${String(nextSeq).padStart(4, '0')}`;

      const draft = await this.prisma.warehouseOrder.create({
        data: {
          orderCode,
          type: dto.type,
          status: 'DRAFT',
          createdBy: actorId,
          note: dto.note ?? `Tạo tự động bởi AI Assistant`,
          items: {
            create: [{
              productId: product.id,
              locationId: locationId ?? null,
              expectedQuantity: qty,
              actualQuantity: 0,
            }],
          },
        },
        include: {
          items: {
            include: {
              product: { select: { id: true, name: true, sku: true, unit: true } },
              location: { select: { id: true, locationBarcode: true } },
            },
          },
        },
      });

      return {
        message: `Đã tạo phiếu nháp ${draft.orderCode} thành công. Vui lòng kiểm tra và xác nhận.`,
        draft: draft as unknown as Record<string, unknown>,
        requiresConfirmation: true,
      };
    } catch (error) {
      this.logger.error('createDraftOrder failed', error);
      return {
        message: 'Có lỗi xảy ra khi tạo phiếu nháp. Vui lòng thử lại.',
        requiresConfirmation: false,
      };
    }
  }
}
