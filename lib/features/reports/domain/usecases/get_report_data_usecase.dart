import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';
import 'package:smart_wms/features/reports/domain/repositories/reports_repository.dart';

/// Retrieves the full inventory report summary.
class GetReportDataUseCase extends UseCase<InventorySummary, NoParams> {
  const GetReportDataUseCase(this._repository);

  final ReportsRepository _repository;

  @override
  FutureEither<InventorySummary> call(NoParams params) {
    return _repository.getReportData();
  }
}
