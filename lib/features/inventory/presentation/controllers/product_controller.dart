import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_products_usecase.dart';

part 'product_controller.g.dart';

@riverpod
class ProductController extends _$ProductController {
  late final GetAllProductsUseCase _getAllProducts;

  @override
  Future<List<Product>> build() async {
    final client = ref.watch(supabaseClientProvider);
    final ds = InventoryRemoteDataSourceImpl(client);
    final repo = InventoryRepositoryImpl(ds);
    _getAllProducts = GetAllProductsUseCase(repo);

    return _fetchProducts();
  }

  Future<List<Product>> _fetchProducts() async {
    final result = await _getAllProducts(const NoParams());
    return result.fold(
      (failure) => throw Exception(failure.message),
      (products) => products,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchProducts);
  }
}
