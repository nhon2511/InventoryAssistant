import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Retrieves all products from the database.
class GetAllProductsUseCase extends UseCase<List<Product>, NoParams> {
  const GetAllProductsUseCase(this._repository);

  final InventoryRepository _repository;

  @override
  FutureEither<List<Product>> call(NoParams params) {
    return _repository.getAllProducts();
  }
}
