import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_catalog_datasource.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_stock_datasource.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  const InventoryRepositoryImpl(
    this._remoteDataSource, {
    this.stockDataSource,
    this.catalogDataSource,
  });

  final InventoryRemoteDataSource _remoteDataSource;
  final NestStockDataSource? stockDataSource;
  final NestCatalogDataSource? catalogDataSource;

  @override
  FutureEither<List<Product>> getAllProducts() async {
    try {
      final models =
          await (catalogDataSource?.products() ??
              _remoteDataSource.getAllProducts());
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Product> getProductByBarcode(String barcode) async {
    try {
      final model =
          await (catalogDataSource?.product(barcode) ??
              _remoteDataSource.getProductByBarcode(barcode));
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Product> getProductById(String id) async {
    try {
      final model =
          await (catalogDataSource?.product(id) ??
              _remoteDataSource.getProductById(id));
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<Location>> getAllLocations() async {
    try {
      final models =
          await (catalogDataSource?.locations() ??
              _remoteDataSource.getAllLocations());
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Location> getLocationByBarcode(String barcode) async {
    try {
      final model =
          await (catalogDataSource?.location(barcode) ??
              _remoteDataSource.getLocationByBarcode(barcode));
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<InventoryItem>> getStockByProduct(String productId) async {
    try {
      final models =
          await (stockDataSource?.getStockByProduct(productId) ??
              _remoteDataSource.getStockByProduct(productId));
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<List<InventoryItem>> getAllInventoryItems() async {
    try {
      final models =
          await (stockDataSource?.getAllInventoryItems() ??
              _remoteDataSource.getAllInventoryItems());
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
