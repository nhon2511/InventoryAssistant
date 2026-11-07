import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft_preview.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/parsed_intent.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Resolves only the single-line entity contract currently represented by NLU.
class ResolveOrderDraftUseCase {
  const ResolveOrderDraftUseCase(this.repository);
  final InventoryRepository repository;
  FutureEither<OrderDraftPreview> call(ParsedIntent intent) async {
    final type = intent.intent == 'create_inbound_draft'
        ? OrderType.inbound
        : intent.intent == 'create_outbound_draft'
        ? OrderType.outbound
        : switch (intent.entities['type']?.toUpperCase()) {
            'INBOUND' => OrderType.inbound,
            'OUTBOUND' => OrderType.outbound,
            _ => null,
          };
    if (type == null) {
      return const Left(
        AiFailure(message: 'Chưa rõ loại phiếu. Hãy nói rõ nhập hoặc xuất.'),
      );
    }
    final quantity = int.tryParse(intent.entities['quantity'] ?? '');
    if (quantity == null || quantity <= 0) {
      return const Left(
        AiFailure(
          message:
              'Bản nháp thiếu số lượng nguyên lớn hơn 0. Hãy bổ sung yêu cầu.',
        ),
      );
    }
    final products = await repository.getAllProducts();
    final locations = await repository.getAllLocations();
    return products.flatMap(
      (ps) => locations.flatMap((ls) {
        final candidates = ps
            .where(
              (p) =>
                  p.id == intent.entities['product_id'] ||
                  p.sku == intent.entities['sku'] ||
                  p.barcode == intent.entities['barcode'] ||
                  p.name.toLowerCase() ==
                      intent.entities['product_name']?.toLowerCase(),
            )
            .toList();
        final bins = ls
            .where(
              (l) =>
                  l.id == intent.entities['location_id'] ||
                  l.locationBarcode == intent.entities['location_barcode'] ||
                  l.displayLabel.toLowerCase() ==
                      intent.entities['location']?.toLowerCase(),
            )
            .toList();
        if (candidates.length != 1 || bins.length != 1) {
          return const Left(
            AiFailure(
              message: 'Không xác định duy nhất sản phẩm/vị trí. Cần SKU hoặc mã vạch và mã vị trí chính xác.',
            ),
          );
        }
        final product = candidates.single;
        return Right(
          OrderDraftPreview(
            type: type,
            note: intent.entities['note'],
            items: [
              WarehouseOrderItem(
                id: 'ai-preview-line',
                orderId: '',
                productId: product.id,
                productName: product.name,
                locationId: bins.single.id,
                expectedQuantity: quantity,
                actualQuantity: 0,
              ),
            ],
          ),
        );
      }),
    );
  }
}
