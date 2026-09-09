import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Gets all stock entries for a specific product.
class GetStockByProductUseCase extends UseCase<List<InventoryItem>, String> {
  const GetStockByProductUseCase(this._repository);

  final InventoryRepository _repository;

  @override
  FutureEither<List<InventoryItem>> call(String productId) {
    return _repository.getStockByProduct(productId);
  }
}
