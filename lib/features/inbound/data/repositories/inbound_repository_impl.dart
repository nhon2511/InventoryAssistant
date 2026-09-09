import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/data/datasources/inbound_remote_datasource.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

class InboundRepositoryImpl implements InboundRepository {
  const InboundRepositoryImpl(this._remoteDataSource);

  final InboundRemoteDataSource _remoteDataSource;

  @override
  FutureEither<WarehouseOrder> createInboundOrder({String? note}) async {
    try {
      final model = await _remoteDataSource.createInboundOrder(note: note);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrderItem> addScannedItem({
    required String orderId,
    required String productId,
    required int quantity,
    String? locationId,
    String? lotNumber,
    DateTime? expiryDate,
  }) async {
    try {
      final model = await _remoteDataSource.addOrderItem(
        orderId: orderId,
        productId: productId,
        quantity: quantity,
        locationId: locationId,
        lotNumber: lotNumber,
        expiryDate: expiryDate?.toIso8601String(),
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrder> confirmInboundOrder(String orderId) async {
    try {
      final model = await _remoteDataSource.confirmInbound(orderId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<WarehouseOrder>> getInboundOrders() async {
    try {
      final models = await _remoteDataSource.getInboundOrders();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrder> getInboundOrderById(String orderId) async {
    try {
      final model = await _remoteDataSource.getOrderById(orderId);
      final items = await _remoteDataSource.getOrderItems(orderId);
      return Right(
        model.toEntity(items: items.map((i) => i.toEntity()).toList()),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
