import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

class ReadInventoryUseCase {
  const ReadInventoryUseCase(this.repository);
  final InventoryRepository repository;
  FutureEither<List<InventoryItem>> stock() =>
      repository.getAllInventoryItems();
  FutureEither<Product> product(String id) => repository.getProductById(id);
  FutureEither<Product> barcode(String code) =>
      repository.getProductByBarcode(code.trim());
  FutureEither<List<InventoryItem>> productStock(String id) =>
      repository.getStockByProduct(id);
}
