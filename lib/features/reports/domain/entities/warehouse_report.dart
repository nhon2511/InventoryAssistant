import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';

class WarehouseReport {
  const WarehouseReport({
    required this.products,
    required this.locations,
    required this.stock,
    required this.orders,
    required this.loadedAt,
  });
  final List<Product> products;
  final List<Location> locations;
  final List<InventoryItem> stock;
  final List<WarehouseOrder> orders;
  final DateTime loadedAt;
  List<WarehouseOrder> between(DateTime? start, DateTime? end) =>
      orders.where((o) {
        if (start == null && end == null) return true;
        final date = o.createdAt;
        if (date == null) return false;
        return (start == null ||
                !date.isBefore(DateTime(start.year, start.month, start.day))) &&
            (end == null ||
                date.isBefore(
                  DateTime(
                    end.year,
                    end.month,
                    end.day,
                  ).add(const Duration(days: 1)),
                ));
      }).toList();
  int availableFor(String productId) => stock
      .where((s) => s.productId == productId)
      .fold(0, (sum, item) => sum + item.quantityAvailable);
  List<Product> get lowStock =>
      products.where((p) => availableFor(p.id) < p.minSafetyStock).toList();
  Map<String, int> get onHandByUnit {
    final result = <String, int>{};
    for (final item in stock) {
      final unit =
          products.where((p) => p.id == item.productId).firstOrNull?.unit ??
          'Không rõ đơn vị';
      result[unit] = (result[unit] ?? 0) + item.quantityOnHand;
    }
    return result;
  }
}
