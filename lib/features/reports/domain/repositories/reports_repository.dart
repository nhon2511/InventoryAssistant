import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';

// This interface is intentional: it keeps domain code independent from the
// reports data source and supports repository substitution in tests.
// ignore: one_member_abstracts
abstract class ReportsRepository {
  FutureEither<InventorySummary> getReportData();
}
