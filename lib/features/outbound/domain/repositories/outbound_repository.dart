import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

/// Abstract repository contract for outbound operations.
abstract class OutboundRepository {
  FutureEither<WarehouseOrder> createOutboundOrder({String? note});

  FutureEither<List<WarehouseOrder>> getOutboundOrders();

  FutureEither<WarehouseOrder> getOutboundOrderById(String orderId);

  /// Calls the `confirm_outbound_order` stored procedure.
  FutureEither<void> confirmOutboundOrder(String orderId);
}
