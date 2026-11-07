import 'package:smart_wms/core/enums/stock_status.dart';
import 'package:smart_wms/features/reports/domain/entities/report_item.dart';

/// Data transfer object that combines product and inventory data
/// for report generation.
class ReportItemModel {
  const ReportItemModel({
    required this.productId,
    required this.sku,
    required this.productName,
    required this.category,
    required this.totalOnHand,
    required this.totalReserved,
    required this.minSafetyStock,
    required this.locationLabel,
  });

  final String productId;
  final String sku;
  final String productName;
  final String category;
  final int totalOnHand;
  final int totalReserved;
  final int minSafetyStock;
  final String locationLabel;

  ReportItem toEntity() {
    return ReportItem(
      productId: productId,
      sku: sku,
      productName: productName,
      category: category,
      totalOnHand: totalOnHand,
      totalReserved: totalReserved,
      minSafetyStock: minSafetyStock,
      locationLabel: locationLabel,
      status: StockStatus.fromQuantity(
        quantityOnHand: totalOnHand,
        minSafetyStock: minSafetyStock,
      ),
    );
  }
}
