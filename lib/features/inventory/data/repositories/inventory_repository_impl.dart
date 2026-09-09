import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(this._remoteDataSource);

  final InventoryRemoteDataSource _remoteDataSource;

  @override
  FutureEither<List<Product>> getAllProducts() async {
    try {
      final models = await _remoteDataSource.getAllProducts();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Product> getProductByBarcode(String barcode) async {
    try {
      final model = await _remoteDataSource.getProductByBarcode(barcode);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Product> getProductById(String id) async {
    try {
      final model = await _remoteDataSource.getProductById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<Location>> getAllLocations() async {
    try {
      final models = await _remoteDataSource.getAllLocations();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Location> getLocationByBarcode(String barcode) async {
    try {
      final model = await _remoteDataSource.getLocationByBarcode(barcode);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<InventoryItem>> getStockByProduct(
    String productId,
  ) async {
    try {
      final models = await _remoteDataSource.getStockByProduct(productId);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<InventoryItem>> getAllInventoryItems() async {
    try {
      final models = await _remoteDataSource.getAllInventoryItems();
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Stream<List<InventoryItem>> subscribeInventoryRealtime() {
    return _remoteDataSource.subscribeInventoryRealtime().map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }
}
