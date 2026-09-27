import 'package:smart_wms/features/dashboard/domain/dashboard_snapshot.dart';

abstract class DashboardRepository {
  Future<DashboardSnapshot> load();
}
