import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_products_usecase.dart';

part 'product_controller.g.dart';

@riverpod
class ProductController extends _$ProductController {
  late final GetAllProductsUseCase _getAllProducts;

  @override
  Future<List<Product>> build() async {
    _getAllProducts = ref.watch(getAllProductsUseCaseProvider);

    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final result = await _getAllProducts(const NoParams());
    return result.fold(
      (failure) => throw StateError(failure.message),
      (products) => products,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProducts);
  }
}
