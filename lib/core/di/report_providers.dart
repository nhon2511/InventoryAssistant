import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/di/order_workspace_providers.dart';
import 'package:smart_wms/features/reports/domain/usecases/load_warehouse_report_usecase.dart';

final loadReportProvider = Provider(
  (ref) => LoadWarehouseReportUseCase(
    ref.watch(inventoryRepositoryProvider),
    ref.watch(readOrdersProvider),
  ),
);
