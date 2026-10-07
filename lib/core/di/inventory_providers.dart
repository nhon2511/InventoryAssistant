import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_locations_usecase.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_products_usecase.dart';
import 'package:smart_wms/features/inventory/domain/usecases/subscribe_inventory_realtime_usecase.dart';

final inventoryRemoteDataSourceProvider = Provider<InventoryRemoteDataSource>((
  ref,
) {
  return InventoryRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepositoryImpl(ref.watch(inventoryRemoteDataSourceProvider));
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
