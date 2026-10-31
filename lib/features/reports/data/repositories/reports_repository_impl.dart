import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/stock_status.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/reports/data/datasources/reports_remote_datasource.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';
import 'package:smart_wms/features/reports/domain/repositories/reports_repository.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._remoteDataSource);

  final ReportsRemoteDataSource _remoteDataSource;

  @override
  FutureEither<InventorySummary> getReportData() async {
    try {
      final models = await _remoteDataSource.getReportItems();
      final items = models.map((m) => m.toEntity()).toList();

      final totalOnHand = items.fold<int>(
        0,
        (sum, item) => sum + item.totalOnHand,
      );
      final lowStockCount = items
          .where((item) => item.status == StockStatus.lowStock)
          .length;
      final outOfStockCount = items
          .where((item) => item.status == StockStatus.outOfStock)
          .length;

      return Right(
        InventorySummary(
          totalProducts: items.length,
          totalStockQuantity: totalOnHand,
          lowStockCount: lowStockCount,
          outOfStockCount: outOfStockCount,
          items: items,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }
}
