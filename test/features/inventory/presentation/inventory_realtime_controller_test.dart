import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_realtime_controller.dart';

class _RealtimeRepository extends PreviewRepository {
  bool cancelled = false;
  late final events = StreamController<List<InventoryItem>>(
    onCancel: () => cancelled = true,
  );

  @override
  Stream<List<InventoryItem>> subscribeInventoryRealtime() => events.stream;

  @override
  Future<void> dispose() async {
    await events.close();
    await super.dispose();
  }
}

void main() {
  test(
    'realtime provider maps payload and cancels subscription on dispose',
    () async {
      final repository = _RealtimeRepository();
      addTearDown(repository.dispose);
      final container = ProviderContainer(
        overrides: [inventoryRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        inventoryRealtimeProvider,
        (_, _) {},
      );
      await container.pump();
      repository.events.add(repository.stock);
      await container.pump();
      expect(
        container.read(inventoryRealtimeProvider).value?.length,
        repository.stock.length,
      );
      subscription.close();
      await container.pump();
      expect(repository.cancelled, isTrue);
    },
  );
}
