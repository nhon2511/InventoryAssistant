import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/orders/data/datasources/nest_order_datasource.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';

class NestOrderWorkflowRepository implements OrderWorkflowRepository {
  const NestOrderWorkflowRepository(this.source);
  final NestOrderDataSource source;
  @override
  bool get available => true;
  @override
  FutureEither<List<WarehouseOrder>> list(OrderType type) async {
    try {
      return Right(await source.list(type));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrder> detail(String id) async {
    try {
      return Right(await source.detail(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrder> saveDraft({
    required OrderType type,
    required String createdBy,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  }) async {
    try {
      return Right(
        await source.saveDraft(
          type: type,
          items: items,
          requestId: requestId,
          note: note,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrder> review({
    required String orderId,
    required OrderStatus expectedStatus,
    required bool approve,
    required String reviewerId,
  }) async {
    if (expectedStatus != OrderStatus.draft) {
      return const Left(
        ServerFailure(message: 'Chỉ có thể duyệt hoặc hủy phiếu nháp.'),
      );
    }
    try {
      return Right(await source.review(orderId, approve: approve));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<OrderConfirmationOutcome> confirm({
    required String orderId,
    required OrderType type,
    required Map<String, int> actualQuantities,
    required String idempotencyKey,
  }) async {
    try {
      return Right(
        await source.confirm(
          orderId: orderId,
          type: type,
          actualQuantities: actualQuantities,
          idempotencyKey: idempotencyKey,
        ),
      );
    } on ServerException catch (error) {
      return Left(
        ServerFailure(message: error.message, statusCode: error.statusCode),
      );
    }
  }
}
