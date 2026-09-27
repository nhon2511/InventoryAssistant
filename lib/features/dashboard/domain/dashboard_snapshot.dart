import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';

class DashboardSnapshot {
  const DashboardSnapshot({required this.productCount, required this.totalStock,
    required this.lowStockCount, required this.outOfStockCount,
    required this.inboundCount, required this.outboundCount,
    required this.inboundByDay, required this.outboundByDay,
    required this.recentOrders, required this.lowStockItems});
  final int productCount, totalStock, lowStockCount, outOfStockCount,
      inboundCount, outboundCount;
  final List<int> inboundByDay, outboundByDay;
  final List<WarehouseOrder> recentOrders;
  final List<InventoryItem> lowStockItems;
}
