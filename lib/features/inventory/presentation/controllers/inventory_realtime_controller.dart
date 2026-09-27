import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_repository_provider.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/usecases/subscribe_inventory_realtime_usecase.dart';

part 'inventory_realtime_controller.g.dart';

/// Provides a realtime stream of [InventoryItem] updates
/// via Supabase Realtime subscriptions.
@riverpod
Stream<List<InventoryItem>> inventoryRealtime(Ref ref) {
  final repo = ref.watch(inventoryRepositoryProvider);
  final useCase = SubscribeInventoryRealtimeUseCase(repo);

  return useCase();
}
