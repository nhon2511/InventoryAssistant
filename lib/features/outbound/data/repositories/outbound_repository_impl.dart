import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/data/datasources/outbound_remote_datasource.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

class OutboundRepositoryImpl implements OutboundRepository {
  const OutboundRepositoryImpl(this._remoteDataSource);

  final OutboundRemoteDataSource _remoteDataSource;

  @override
  FutureEither<WarehouseOrder> createOutboundOrder({String? note}) async {
    try {
      final model = await _remoteDataSource.createOutboundOrder(note: note);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<WarehouseOrder>> getOutboundOrders() async {
    try {
      final models = await _remoteDataSource.getOutboundOrders();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<WarehouseOrder> getOutboundOrderById(String orderId) async {
    try {
      final model = await _remoteDataSource.getOrderById(orderId);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureVoid confirmOutboundOrder(String orderId) async {
    try {
      await _remoteDataSource.confirmOutbound(orderId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
