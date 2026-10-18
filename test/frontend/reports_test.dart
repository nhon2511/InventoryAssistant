import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';
import 'package:smart_wms/features/reports/presentation/services/report_exporter.dart';

void main() {
  test('report separates units, includes missing stock in alerts, and exports received rows', () {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    final report = WarehouseReport(
      products: repository.products,
      locations: repository.locations,
      stock: repository.stock,
      orders: repository.orders,
      loadedAt: DateTime(2026, 10, 12),
    );
    expect(report.onHandByUnit, {'đôi': 80, 'cuộn': 24, 'cái': 120});
    expect(report.lowStock.map((p) => p.id), ['p-2']);
    const exporter = ReportExporter();
    final bytes = exporter.excel(report, null, null);
    final workbook = Excel.decodeBytes(bytes);
    expect(workbook.sheets['Ton hien tai']!.maxRows, 4);
    expect(workbook.sheets['Lich su phieu']!.maxRows, 4);
    expect(workbook.sheets['Ton hien tai']!.rows[1][6]!.value.toString(), '70');
    expect(exporter.stockRows(report)[1][1], 'Găng tay bảo hộ');
  });
  test('date filter includes entire end day and excludes undated rows only while filtering', () {
    final report = WarehouseReport(
      products: const [],
      locations: const [],
      stock: const [],
      loadedAt: DateTime(2026),
      orders: [
        WarehouseOrder(
          id: 'end',
          orderCode: 'end',
          type: OrderType.inbound,
          status: OrderStatus.draft,
          createdAt: DateTime(2026, 10, 12, 23, 59),
        ),
        WarehouseOrder(
          id: 'after',
          orderCode: 'after',
          type: OrderType.inbound,
          status: OrderStatus.draft,
          createdAt: DateTime(2026, 10, 13),
        ),
        const WarehouseOrder(
          id: 'unknown',
          orderCode: 'unknown',
          type: OrderType.inbound,
          status: OrderStatus.draft,
        ),
      ],
    );
    expect(
      report
          .between(DateTime(2026, 10, 12), DateTime(2026, 10, 12))
          .map((o) => o.id),
      ['end'],
    );
    expect(report.between(null, null).length, 3);
  });
}
