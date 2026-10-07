import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';

part 'inventory_realtime_controller.g.dart';

/// Provides a realtime stream of [InventoryItem] updates
/// via Supabase Realtime subscriptions.
@riverpod
Stream<List<InventoryItem>> inventoryRealtime(Ref ref) {
  return ref.watch(subscribeInventoryRealtimeUseCaseProvider).call();
}
