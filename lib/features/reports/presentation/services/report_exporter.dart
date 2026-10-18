import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';

class ReportExporter {
  const ReportExporter();
  List<List<String>> stockRows(WarehouseReport report) => [
    ['SKU', 'Sản phẩm', 'Đơn vị', 'Vị trí', 'Thực có', 'Giữ chỗ', 'Khả dụng'],
    for (final item in report.stock)
      [
        report.products.where((p) => p.id == item.productId).firstOrNull?.sku ??
            item.productId,
        report.products
                .where((p) => p.id == item.productId)
                .firstOrNull
                ?.name ??
            item.productName ??
            item.productId,
        report.products
                .where((p) => p.id == item.productId)
                .firstOrNull
                ?.unit ??
            '—',
        report.locations
                .where((l) => l.id == item.locationId)
                .firstOrNull
                ?.displayLabel ??
            item.locationLabel ??
            item.locationId,
        '${item.quantityOnHand}',
        '${item.quantityReserved}',
        '${item.quantityAvailable}',
      ],
  ];
  List<List<String>> historyRows(
    WarehouseReport report,
    DateTime? start,
    DateTime? end,
  ) => [
    ['Mã phiếu', 'Loại', 'Trạng thái DB', 'Người tạo', 'Ngày tạo', 'Ghi chú'],
    for (final order in report.between(start, end))
      [
        order.orderCode,
        order.type.dbValue,
        order.status.dbValue,
        order.createdBy ?? '—',
        if (order.createdAt == null)
          '—'
        else
          DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt!),
        order.note ?? '',
      ],
  ];
  Uint8List excel(WarehouseReport report, DateTime? start, DateTime? end) {
    final book = Excel.createExcel()..rename('Sheet1', 'Ton hien tai');
    for (final entry in {
      'Ton hien tai': stockRows(report),
      'Lich su phieu': historyRows(report, start, end),
    }.entries) {
      for (final row in entry.value.indexed) {
        book[entry.key].appendRow([
          for (final cell in row.$2.indexed)
            if (entry.key == 'Ton hien tai' && row.$1 > 0 && cell.$1 >= 4)
              IntCellValue(int.parse(cell.$2))
            else
              TextCellValue(cell.$2),
        ]);
      }
    }
    book['Pham vi'].appendRow([
      TextCellValue(
        'Tồn hiện tại; lịch sử theo ngày tạo phiếu. Không phải sổ nhập/xuất/tồn đầu-cuối kỳ. Snapshot: ${report.loadedAt.toIso8601String()}',
      ),
    ]);
    return Uint8List.fromList(book.encode()!);
  }

  Future<Uint8List> pdf(
    WarehouseReport report,
    DateTime? start,
    DateTime? end, {
    required pw.Font font,
  }) async {
    final document = pw.Document()
      ..addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          theme: pw.ThemeData.withFont(base: font, bold: font),
          build: (_) => [
            pw.Text(
              'Smart WMS · Báo cáo dữ liệu đã nhận',
              style: const pw.TextStyle(fontSize: 18),
            ),
            pw.Text(
              'Tồn hiện tại; lịch sử lọc theo ngày tạo. Không xác nhận giao dịch tồn.',
            ),
            pw.Text(
              'Thời điểm tải: ${DateFormat("dd/MM/yyyy HH:mm").format(report.loadedAt)}',
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              data: stockRows(report),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Lịch sử phiếu'),
            pw.TableHelper.fromTextArray(
              data: historyRows(report, start, end),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      );
    return document.save();
  }
}
