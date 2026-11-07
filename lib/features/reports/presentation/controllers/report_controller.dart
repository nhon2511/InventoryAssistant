import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/report_providers.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';

final warehouseReportProvider = FutureProvider<WarehouseReport>((ref) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) throw StateError('Chưa đăng nhập.');
  final result = await ref.watch(loadReportProvider)(auth.profile);
  return result.fold((f) => throw StateError(f.message), (report) => report);
});
