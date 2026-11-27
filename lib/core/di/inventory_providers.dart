import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_catalog_datasource.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_stock_datasource.dart';
import 'package:smart_wms/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_locations_usecase.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_products_usecase.dart';
import 'package:smart_wms/features/inventory/domain/usecases/subscribe_inventory_realtime_usecase.dart';

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((
  ref,
) {
  return InventoryRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final nestApiClientProvider = Provider<NestApiClient>((ref) {
  final httpClient = http.Client();
  ref.onDispose(httpClient.close);
  final supabase = ref.watch(supabaseClientProvider);
  return NestApiClient(
    httpClient,
    () => supabase.auth.currentSession?.accessToken,
  );
});

final nestCatalogDataSourceProvider = Provider<NestCatalogDataSource>(
  (ref) => NestCatalogDataSource(ref.watch(nestApiClientProvider)),
);

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(
    ref.watch(inventoryRemoteDataSourceProvider),
    stockDataSource: NestStockDataSource(ref.watch(nestApiClientProvider)),
    catalogDataSource: ref.watch(nestCatalogDataSourceProvider),
  );
});

final stockOverviewItemsProvider =
    FutureProvider.autoDispose<List<InventoryItem>>((ref) async {
      final result = await ref
          .watch(inventoryRepositoryProvider)
          .getAllInventoryItems();
      return result.fold(
        (failure) => throw StateError(failure.message),
        (items) => items,
      );
    });

final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>((ref) {
  return GetAllProductsUseCase(ref.watch(inventoryRepositoryProvider));
});

final getAllLocationsUseCaseProvider = Provider<GetAllLocationsUseCase>((ref) {
  return GetAllLocationsUseCase(ref.watch(inventoryRepositoryProvider));
});

final subscribeInventoryRealtimeUseCaseProvider =
    Provider<SubscribeInventoryRealtimeUseCase>((ref) {
      return SubscribeInventoryRealtimeUseCase(
        ref.watch(inventoryRepositoryProvider),
      );
    });
