import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_maintenance_repository.dart';

class PendingInventoryMaintenanceRepository
    implements InventoryMaintenanceRepository {
  const PendingInventoryMaintenanceRepository();
  static const failure = ServerFailure(
    message: 'Chưa khả dụng: backend chưa cung cấp contract quản lý sản phẩm/vị trí.',
  );
  @override
  bool get available => false;
  @override
  FutureEither<Product> saveProduct(Product product) async =>
      const Left(failure);
  @override
  FutureVoid deleteProduct(String id) async => const Left(failure);
  @override
  FutureEither<Location> saveLocation(Location location) async =>
      const Left(failure);
  @override
  FutureVoid deleteLocation(String id) async => const Left(failure);
}
