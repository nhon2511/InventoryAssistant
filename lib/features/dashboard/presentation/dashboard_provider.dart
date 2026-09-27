import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/features/dashboard/data/warehouse_dashboard_repository.dart';
import 'package:smart_wms/features/dashboard/domain/dashboard_repository.dart';
import 'package:smart_wms/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:smart_wms/features/inbound/presentation/controllers/inbound_repository_provider.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_repository_provider.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/outbound_repository_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) =>
  WarehouseDashboardRepository(ref.watch(inventoryRepositoryProvider),
    ref.watch(inboundRepositoryProvider), ref.watch(outboundRepositoryProvider)));
final dashboardProvider = FutureProvider.autoDispose<DashboardSnapshot>(
  (ref) => ref.watch(dashboardRepositoryProvider).load());
