import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';

/// Separate capability until a backend adapter is supplied. Never infers APIs.
abstract class InventoryMaintenanceRepository {
  bool get available;
  FutureEither<Product> saveProduct(Product product);
  FutureVoid deleteProduct(String id);
  FutureEither<Location> saveLocation(Location location);
  FutureVoid deleteLocation(String id);
}
