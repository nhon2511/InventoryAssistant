import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';
import 'package:smart_wms/features/ai_assistant/domain/repositories/ai_assistant_repository.dart';
import 'package:smart_wms/features/inventory/data/repositories/mock_inventory_repository.dart';

/// Deterministic offline responses for the UI demonstration.
class MockAiAssistantRepository implements AiAssistantRepository {
  const MockAiAssistantRepository();

  @override
  FutureEither<ParsedIntent> parseIntent(String userText) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final text = userText.toLowerCase();
    if (text.contains('nhập') || text.contains('xuất') || text.contains('lấy')) {
      return Right(ParsedIntent(
        intent: 'create_order',
        confidence: 0.95,
        entities: {
          'type': text.contains('xuất') || text.contains('lấy') ? 'outbound' : 'inbound',
          if (text.contains('hảo hảo')) 'product_name': 'Mì Hảo Hảo',
        },
      ));
    }
    return Right(ParsedIntent(
      intent: 'query_stock',
      confidence: 0.95,
      entities: {if (text.contains('hảo hảo')) 'product_name': 'Mì Hảo Hảo'},
    ));
  }

  @override
  FutureEither<String> queryStock(Map<String, String> entities) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final productName = entities['product_name'];
    if (productName != null) {
      for (final product in mockInventoryRepository.products) {
        if (product.name.toLowerCase() == productName.toLowerCase()) {
          final available = mockInventoryRepository.items
              .where((item) => item.productId == product.id)
              .fold<int>(0, (sum, item) => sum + item.quantityAvailable);
          return Right('${product.name}: còn $available ${product.unit}.');
        }
      }
      return const Right('Không tìm thấy sản phẩm này trong kho mẫu.');
    }
    return Right('Kho mẫu có ${mockInventoryRepository.products.length} sản phẩm. Hãy mở mục Sản phẩm để xem số lượng từng mặt hàng.');
  }
}
