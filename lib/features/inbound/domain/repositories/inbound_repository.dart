import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

/// Abstract repository contract for inbound operations.
abstract class InboundRepository {
  FutureEither<WarehouseOrder> createInboundOrder({String? note});

  FutureEither<WarehouseOrderItem> addScannedItem({
    required String orderId,
    required String productId,
    required int quantity,
    String? locationId,
    String? lotNumber,
    DateTime? expiryDate,
  });

  FutureEither<WarehouseOrder> confirmInboundOrder(String orderId);

  FutureEither<List<WarehouseOrder>> getInboundOrders();

  FutureEither<WarehouseOrder> getInboundOrderById(String orderId);
}
