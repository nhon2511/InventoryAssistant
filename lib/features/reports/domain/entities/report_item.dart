import 'package:smart_wms/core/enums/stock_status.dart';

/// Domain entity representing a single line in an inventory report.
///
/// Combines product metadata with aggregated stock quantities
/// across all warehouse locations.
class ReportItem {
  const ReportItem({
    required this.productId,
    required this.sku,
    required this.productName,
    required this.category,
    required this.totalOnHand,
    required this.totalReserved,
    required this.minSafetyStock,
    required this.locationLabel,
    required this.status,
  });

  final String productId;
  final String sku;
  final String productName;

  /// Product category, derived from the product unit.
  final String category;

  /// Total quantity on hand across all locations.
  final int totalOnHand;

  /// Total reserved quantity across all locations.
  final int totalReserved;

  /// Minimum safety stock threshold from product definition.
  final int minSafetyStock;

  /// Comma-separated location labels where this product is stored.
  final String locationLabel;

  /// Computed stock safety status.
  final StockStatus status;

  /// Available = on hand − reserved.
  int get totalAvailable => totalOnHand - totalReserved;
}
