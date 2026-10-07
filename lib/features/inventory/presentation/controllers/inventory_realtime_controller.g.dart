// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_realtime_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides a realtime stream of [InventoryItem] updates
/// via Supabase Realtime subscriptions.

@ProviderFor(inventoryRealtime)
final inventoryRealtimeProvider = InventoryRealtimeProvider._();

/// Provides a realtime stream of [InventoryItem] updates
/// via Supabase Realtime subscriptions.

final class InventoryRealtimeProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<InventoryItem>>,
          List<InventoryItem>,
          Stream<List<InventoryItem>>
        >
    with
        $FutureModifier<List<InventoryItem>>,
        $StreamProvider<List<InventoryItem>> {
  /// Provides a realtime stream of [InventoryItem] updates
  /// via Supabase Realtime subscriptions.
  InventoryRealtimeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inventoryRealtimeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inventoryRealtimeHash();

  @$internal
  @override
  $StreamProviderElement<List<InventoryItem>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<InventoryItem>> create(Ref ref) {
    return inventoryRealtime(ref);
  }
}

String _$inventoryRealtimeHash() => r'36a0251fe6d697dcafd1089d02f06da267d91246';
