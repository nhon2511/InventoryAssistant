import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/inventory_workspace_providers.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';

export 'package:smart_wms/core/di/inventory_workspace_providers.dart';

final stockSnapshotProvider = FutureProvider<List<InventoryItem>>((ref) async {
  final result = await ref.watch(readInventoryProvider).stock();
  return result.fold((f) => throw StateError(f.message), (items) => items);
});
final productDetailProvider = FutureProvider.family<Product, String>((
  ref,
  id,
) async {
  final result = await ref.watch(readInventoryProvider).product(id);
  return result.fold((f) => throw StateError(f.message), (product) => product);
});
final productStockProvider = FutureProvider.family<List<InventoryItem>, String>(
  (ref, id) async {
    final result = await ref.watch(readInventoryProvider).productStock(id);
    return result.fold((f) => throw StateError(f.message), (items) => items);
  },
);
