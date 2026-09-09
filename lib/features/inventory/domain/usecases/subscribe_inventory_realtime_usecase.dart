import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Provides a realtime stream of inventory items via Supabase Realtime.
class SubscribeInventoryRealtimeUseCase {
  const SubscribeInventoryRealtimeUseCase(this._repository);

  final InventoryRepository _repository;

  Stream<List<InventoryItem>> call() {
    return _repository.subscribeInventoryRealtime();
  }
}
