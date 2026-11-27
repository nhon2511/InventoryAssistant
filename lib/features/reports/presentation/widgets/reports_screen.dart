import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';
import 'package:smart_wms/features/reports/presentation/controllers/report_controller.dart';
import 'package:smart_wms/features/reports/presentation/services/report_exporter.dart';

/// Current NestJS stock snapshot and order headers, not a period ledger.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTime? start;
  DateTime? end;
  bool exporting = false;
  static const exporter = ReportExporter();

  Future<void> chooseDate({required bool from}) async {
    final date = await showDatePicker(
      context: context,
      initialDate: (from ? start : end) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (from) {
        start = date;
      } else {
        end = date;
      }
    });
  }

  Future<void> export(WarehouseReport report, String kind) async {
    if (exporting) return;
    if (start != null && end != null && start!.isAfter(end!)) {
      showMessage('Ngày bắt đầu phải trước hoặc bằng ngày kết thúc.');
      return;
    }
    setState(() => exporting = true);
    try {
      final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      if (kind == 'excel') {
        final bytes = exporter.excel(report, start, end);
        await Share.shareXFiles([
          XFile.fromData(
            bytes,
            name: 'bao_cao_kho_$stamp.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ]).timeout(const Duration(seconds: 30));
      } else {
        final font = pw.Font.ttf(
          await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
        );
        final bytes = await exporter.pdf(report, start, end, font: font);
        if (kind == 'pdf') {
          await Printing.layoutPdf(
            onLayout: (_) async => bytes,
            name: 'bao_cao_kho_$stamp.pdf',
          ).timeout(const Duration(seconds: 30));
        } else {
          await Printing.sharePdf(
            bytes: bytes,
            filename: 'bao_cao_kho_$stamp.pdf',
          ).timeout(const Duration(seconds: 30));
        }
      }
    } on Object {
      if (mounted) {
        showMessage(
          'Không thể xuất hoặc chia sẻ file. Hãy thử lại trên thiết bị này.',
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: AsyncPanel(
      value: ref.watch(warehouseReportProvider),
      onRetry: () => ref.invalidate(warehouseReportProvider),
      builder: (report) {
        final invalidDates =
            start != null && end != null && start!.isAfter(end!);
        final orders = invalidDates
            ? <WarehouseOrder>[]
            : report.between(start, end);
        final rows = exporter.stockRows(report);
        return WorkspaceContent(
          child: ListView(
            padding: workspacePadding(context),
            children: [
              WorkspaceHeader(
                title: 'Báo cáo kho',
                description: 'Tồn hiện tại và danh sách phiếu theo ngày tạo từ dữ liệu đã tải.',
                actions: [
                  IconButton(
                    tooltip: 'Làm mới báo cáo',
                    onPressed: () => ref.invalidate(warehouseReportProvider),
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              Text(
                'Snapshot: ${DateFormat('dd/MM/yyyy HH:mm').format(report.loadedAt)}',
              ),
              const Text(
                'Không phải tồn đầu/cuối kỳ hoặc lịch sử biến động; chưa đối chiếu ledger.',
              ),
              const SizedBox(height: 16),
              Text(
                'Tồn hiện tại theo đơn vị',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (report.stock.isEmpty)
                const Text('Chưa có dòng tồn kho trong dữ liệu trả về.'),
              for (final entry in report.onHandByUnit.entries)
                ListTile(
                  title: Text(entry.key),
                  trailing: Text('${entry.value}'),
                ),
              const SizedBox(height: 12),
              for (final row in rows.skip(1))
                Card(
                  child: ListTile(
                    title: Text('${row[1]} · ${row[0]}'),
                    subtitle: Text(
                      'Vị trí: ${row[3]} · Giữ chỗ: ${row[5]} · Khả dụng: ${row[6]}',
                    ),
                    trailing: Text('${row[4]} ${row[2]}'),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                'Phiếu theo ngày tạo',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => chooseDate(from: true),
                    child: Text(
                      start == null
                          ? 'Từ ngày'
                          : 'Từ ${DateFormat('dd/MM/yyyy').format(start!)}',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => chooseDate(from: false),
                    child: Text(
                      end == null
                          ? 'Đến ngày'
                          : 'Đến ${DateFormat('dd/MM/yyyy').format(end!)}',
                    ),
                  ),
                  if (start != null || end != null)
                    TextButton(
                      onPressed: () => setState(() {
                        start = null;
                        end = null;
                      }),
                      child: const Text('Xóa lọc'),
                    ),
                ],
              ),
              if (invalidDates)
                Text(
                  'Khoảng ngày không hợp lệ.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (orders.isEmpty && !invalidDates)
                const Text('Không có phiếu trong khoảng ngày đã chọn.'),
              for (final order in orders)
                ListTile(
                  title: Text(order.orderCode),
                  subtitle: Text(
                    '${order.type.dbValue} · ${order.status.dbValue}',
                  ),
                  trailing: Text(
                    order.createdAt == null
                        ? 'Chưa có ngày tạo'
                        : DateFormat('dd/MM/yyyy').format(order.createdAt!),
                  ),
                ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: exporting || invalidDates
                        ? null
                        : () => export(report, 'excel'),
                    icon: const Icon(Icons.table_chart_outlined),
                    label: const Text('Xuất Excel'),
                  ),
                  OutlinedButton.icon(
                    onPressed: exporting || invalidDates
                        ? null
                        : () => export(report, 'pdf'),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Xem PDF'),
                  ),
                  OutlinedButton.icon(
                    onPressed: exporting || invalidDates
                        ? null
                        : () => export(report, 'share'),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Chia sẻ PDF'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}
