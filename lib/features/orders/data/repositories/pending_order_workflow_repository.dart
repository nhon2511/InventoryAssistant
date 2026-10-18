import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';

class PendingOrderWorkflowRepository implements OrderWorkflowRepository {
  const PendingOrderWorkflowRepository();
  static const failure = ServerFailure(
    message: 'Chưa khả dụng: chờ backend lưu phiếu và dòng hàng nguyên tử, duyệt/từ chối có kiểm tra trạng thái.',
  );
  @override
  bool get available => false;
  @override
  FutureEither<WarehouseOrder> saveDraft({
    required OrderType type,
    required String createdBy,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  }) async => const Left(failure);
  @override
  FutureEither<WarehouseOrder> review({
    required String orderId,
    required OrderStatus expectedStatus,
    required bool approve,
    required String reviewerId,
  }) async => const Left(failure);
}
