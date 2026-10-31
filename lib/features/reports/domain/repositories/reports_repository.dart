import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';

/// Abstract repository contract for report data operations.
abstract class ReportsRepository {
  /// Fetches aggregated inventory data for the reports screen.
  FutureEither<InventorySummary> getReportData();
}
