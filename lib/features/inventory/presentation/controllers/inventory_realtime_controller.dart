import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/usecases/subscribe_inventory_realtime_usecase.dart';

part 'inventory_realtime_controller.g.dart';

/// Provides a realtime stream of [InventoryItem] updates
/// via Supabase Realtime subscriptions.
@riverpod
Stream<List<InventoryItem>> inventoryRealtime(InventoryRealtimeRef ref) {
  final client = ref.watch(supabaseClientProvider);
  final ds = InventoryRemoteDataSourceImpl(client);
  final repo = InventoryRepositoryImpl(ds);
  final useCase = SubscribeInventoryRealtimeUseCase(repo);

  return useCase();
}
