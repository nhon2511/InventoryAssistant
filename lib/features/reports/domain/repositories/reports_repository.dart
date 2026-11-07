import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';

abstract class ReportsRepository {
  FutureEither<InventorySummary> getReportData();
}
