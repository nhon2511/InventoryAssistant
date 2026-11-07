import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

/// Atomic draft/approval capability. Backend adapter intentionally pending.
abstract class OrderWorkflowRepository {
  bool get available;
  FutureEither<WarehouseOrder> saveDraft({
    required OrderType type,
    required String createdBy,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  });

  /// Changes workflow state only. Does not imply a stock transaction.
  FutureEither<WarehouseOrder> review({
    required String orderId,
    required OrderStatus expectedStatus,
    required bool approve,
    required String reviewerId,
  });
}
