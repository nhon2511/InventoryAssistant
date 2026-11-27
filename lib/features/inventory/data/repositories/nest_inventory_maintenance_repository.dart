import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_catalog_datasource.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_maintenance_repository.dart';

class NestInventoryMaintenanceRepository
    implements InventoryMaintenanceRepository {
  const NestInventoryMaintenanceRepository(this.source);
  final NestCatalogDataSource source;
  @override
  bool get available => true;

  @override
  FutureEither<Product> saveProduct(Product product) async {
    try {
      return Right((await source.saveProduct(product)).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureEither<Location> saveLocation(Location location) async {
    try {
      return Right((await source.saveLocation(location)).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureVoid deleteProduct(String id) async {
    try {
      await source.deleteProduct(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  FutureVoid deleteLocation(String id) async {
    try {
      await source.deleteLocation(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
