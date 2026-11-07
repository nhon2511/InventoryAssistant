import 'package:smart_wms/features/reports/domain/entities/report_item.dart';

/// Aggregate inventory statistics used by the Reports screen.
class InventorySummary {
  const InventorySummary({
    required this.totalProducts,
    required this.totalStockQuantity,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.items,
  });

  /// Total number of distinct products.
  final int totalProducts;

  /// Sum of quantityOnHand across every product and location.
  final int totalStockQuantity;

  /// Products whose on-hand quantity is at or below safety stock.
  final int lowStockCount;

  /// Products with zero on-hand quantity.
  final int outOfStockCount;

  /// Full list of report line items.
  final List<ReportItem> items;
}
