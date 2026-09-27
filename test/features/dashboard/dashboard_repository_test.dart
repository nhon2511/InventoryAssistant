import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/features/dashboard/data/warehouse_dashboard_repository.dart';
import 'package:smart_wms/features/inbound/data/repositories/mock_inbound_repository.dart';
import 'package:smart_wms/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:smart_wms/features/outbound/data/repositories/mock_outbound_repository.dart';

void main() {
  test('aggregates offline stock and recent order counts', () async {
    final data = await WarehouseDashboardRepository(
      MockInventoryRepository(), MockInboundRepository(), MockOutboundRepository(),
    ).load();
    expect(data.productCount, 20);
    expect(data.lowStockCount, greaterThan(0));
    expect(data.outOfStockCount, greaterThan(0));
    expect(data.inboundCount, 4);
    expect(data.outboundCount, 3);
    expect(data.inboundByDay.reduce((a, b) => a + b), 4);
    expect(data.outboundByDay.reduce((a, b) => a + b), 3);
  });
}
