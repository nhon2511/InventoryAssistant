import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_maintenance_repository.dart';

class MaintainInventoryUseCase {
  const MaintainInventoryUseCase(this.repository);
  final InventoryMaintenanceRepository repository;

  FutureEither<Product> saveProduct(Product product, UserRole role) async {
    if (!role.isAdmin) {
      return const Left(
        ServerFailure(message: 'Chỉ Admin được quản lý sản phẩm.'),
      );
    }
    if ([
          product.name,
          product.sku,
          product.barcode,
          product.unit,
        ].any((v) => v.trim().isEmpty) ||
        product.minSafetyStock < 0) {
      return const Left(
        ServerFailure(
          message: 'Điền đủ tên, SKU, mã vạch, đơn vị; tồn an toàn không âm.',
        ),
      );
    }
    return repository.saveProduct(product);
  }

  FutureVoid deleteProduct(String id, UserRole role) async => role.isAdmin
      ? repository.deleteProduct(id)
      : const Left(ServerFailure(message: 'Chỉ Admin được xóa sản phẩm.'));

  FutureEither<Location> saveLocation(Location location, UserRole role) async {
    if (!role.isAdmin) {
      return const Left(
        ServerFailure(message: 'Chỉ Admin được quản lý vị trí.'),
      );
    }
    if ([
          location.zoneCode,
          location.aisleCode,
          location.rackCode,
          location.binCode,
          location.locationBarcode,
        ].any((v) => v.trim().isEmpty) ||
        (location.maxCapacityKg != null &&
            (!location.maxCapacityKg!.isFinite ||
                location.maxCapacityKg! <= 0))) {
      return const Left(
        ServerFailure(
          message: 'Điền đủ mã vị trí; sức chứa phải lớn hơn 0 nếu cung cấp.',
        ),
      );
    }
    return repository.saveLocation(location);
  }

  FutureVoid deleteLocation(String id, UserRole role) async => role.isAdmin
      ? repository.deleteLocation(id)
      : const Left(ServerFailure(message: 'Chỉ Admin được xóa vị trí.'));
}
