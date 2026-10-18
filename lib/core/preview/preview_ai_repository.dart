import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';

/// Deterministic fixture, never presented as an LLM integration.
class PreviewAiRepository implements AiAssistantRepository {
  const PreviewAiRepository(this.inventory);
  final PreviewRepository inventory;
  @override
  FutureEither<ParsedIntent> parseIntent(String text) async {
    final normalized = text.toLowerCase();
    final draft = normalized.contains('nháp');
    return Right(
      ParsedIntent(
        intent: draft
            ? normalized.contains('xuất')
                  ? 'create_outbound_draft'
                  : 'create_inbound_draft'
            : 'query_stock',
        confidence: 1,
        entities: draft
            ? {
                'product_id': 'p-1',
                'location_id': 'l-1',
                'quantity': '5',
                'note':
                    'Mô phỏng bản nháp AI; không phải phân tích ngôn ngữ thực.',
              }
            : {'product_name': 'Găng tay bảo hộ'},
      ),
    );
  }

  @override
  FutureEither<String> queryStock(Map<String, String> entities) async =>
      const Right(
        'Mô phỏng: Găng tay bảo hộ có 70 đôi khả dụng tại A-01-01-01 (80 thực có − 10 giữ chỗ).',
      );
}
