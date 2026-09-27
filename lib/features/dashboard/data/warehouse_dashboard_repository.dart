import 'package:smart_wms/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_wms/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

class WarehouseDashboardRepository implements DashboardRepository {
  const WarehouseDashboardRepository(this.inventory, this.inbound, this.outbound);
  final InventoryRepository inventory;
  final InboundRepository inbound;
  final OutboundRepository outbound;

  @override
  Future<DashboardSnapshot> load() async {
    final productsResult = await inventory.getAllProducts();
    final stockResult = await inventory.getAllInventoryItems();
    final inboundResult = await inbound.getInboundOrders();
    final outboundResult = await outbound.getOutboundOrders();
    final products = productsResult.fold((failure) => throw StateError(failure.message), (value) => value);
    final stock = stockResult.fold((failure) => throw StateError(failure.message), (value) => value);
    final inboundOrders = inboundResult.fold((failure) => throw StateError(failure.message), (value) => value);
    final outboundOrders = outboundResult.fold((failure) => throw StateError(failure.message), (value) => value);

    final quantities = <String, int>{};
    final itemByProduct = <String, InventoryItem>{};
    for (final item in stock) {
      quantities.update(item.productId, (old) => old + item.quantityAvailable,
          ifAbsent: () => item.quantityAvailable);
      itemByProduct.putIfAbsent(item.productId, () => item);
    }
    var low = 0;
    var empty = 0;
    final lowItems = <InventoryItem>[];
    for (final product in products) {
      final quantity = quantities[product.id] ?? 0;
      if (quantity <= 0) {
        empty++;
      } else if (quantity <= product.minSafetyStock) {
        low++;
      }
      if (quantity <= product.minSafetyStock && itemByProduct.containsKey(product.id)) {
        lowItems.add(itemByProduct[product.id]!);
      }
    }
    final recent = [...inboundOrders, ...outboundOrders]
      ..sort((a, b) => (b.createdAt ?? DateTime(1970)).compareTo(a.createdAt ?? DateTime(1970)));
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    List<int> daily(List<WarehouseOrder> orders) {
      final counts = List<int>.filled(7, 0);
      for (final order in orders) {
        final date = order.createdAt;
        if (date == null) continue;
        final index = DateTime(date.year, date.month, date.day).difference(start).inDays;
        if (index >= 0 && index < 7) counts[index]++;
      }
      return counts;
    }
    return DashboardSnapshot(
      productCount: products.length,
      totalStock: stock.fold<int>(0, (sum, item) => sum + item.quantityOnHand),
      lowStockCount: low, outOfStockCount: empty,
      inboundCount: inboundOrders.length, outboundCount: outboundOrders.length,
      inboundByDay: daily(inboundOrders), outboundByDay: daily(outboundOrders),
      recentOrders: recent.take(6).toList(), lowStockItems: lowItems.take(6).toList(),
    );
  }
}
