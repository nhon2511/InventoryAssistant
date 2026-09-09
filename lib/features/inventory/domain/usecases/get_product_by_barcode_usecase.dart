import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Looks up a product by its barcode string.
class GetProductByBarcodeUseCase extends UseCase<Product, String> {
  const GetProductByBarcodeUseCase(this._repository);

  final InventoryRepository _repository;

  @override
  FutureEither<Product> call(String barcode) {
    return _repository.getProductByBarcode(barcode);
  }
}
