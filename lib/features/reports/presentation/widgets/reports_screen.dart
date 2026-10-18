import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_labels.dart';
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';
import 'package:smart_wms/features/reports/presentation/controllers/report_controller.dart';
import 'package:smart_wms/features/reports/presentation/services/report_exporter.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});
  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  DateTimeRange? range;
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: AsyncPanel(
      value: ref.watch(warehouseReportProvider),
      onRetry: () => ref.invalidate(warehouseReportProvider),
      builder: (report) => WorkspaceContent(
        child: ListView(
          padding: workspacePadding(context),
          children: [
            WorkspaceHeader(
              title: 'Báo cáo kho',
              description: 'Tồn hiện tại và lịch sử phiếu.',
              actions: [
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(warehouseReportProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại dữ liệu'),
                ),
              ],
            ),
            const Text(
              'Tồn hiện tại và lịch sử phiếu · Chưa có ledger để tính tồn đầu/cuối kỳ hoặc lượng nhập/xuất thực tế.',
            ),
            Text(
              'Dữ liệu tải lúc ${DateFormat("dd/MM/yyyy HH:mm").format(report.loadedAt)}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: range,
                    );
                    if (selected != null && mounted) {
                      setState(() => range = selected);
                    }
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    range == null
                        ? 'Lọc ngày tạo phiếu'
                        : '${DateFormat("dd/MM").format(range!.start)} – ${DateFormat("dd/MM/yyyy").format(range!.end)}',
                  ),
                ),
                if (range != null)
                  TextButton(
                    onPressed: () => setState(() => range = null),
                    child: const Text('Bỏ lọc'),
                  ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => export(report, asPdf: false),
                  icon: const Icon(Icons.table_chart_outlined),
                  label: const Text('Xuất Excel'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => export(report, asPdf: true),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Xuất PDF'),
                ),
              ],
            ),
            if (busy) const LinearProgressIndicator(),
            const Divider(height: 32),
            Text(
              'Tồn hiện tại (không lọc theo ngày)',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (report.stock.isEmpty) const Text('Chưa có tồn kho.'),
            for (final item in report.stock)
              ListTile(
                title: Text(
                  item.productName ??
                      report.products
                          .where((p) => p.id == item.productId)
                          .firstOrNull
                          ?.name ??
                      item.productId,
                ),
                subtitle: Text(
                  '${item.locationLabel ?? item.locationId}\nThực có ${item.quantityOnHand} · Giữ chỗ ${item.quantityReserved} · Khả dụng ${item.quantityAvailable}',
                ),
                isThreeLine: true,
              ),
            const Divider(height: 32),
            Text(
              'Lịch sử phiếu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (report.between(range?.start, range?.end).isEmpty)
              const Text('Không có phiếu trong khoảng đã chọn.'),
            for (final order in report.between(range?.start, range?.end))
              ListTile(
                title: Text(order.orderCode),
                subtitle: Text(
                  '${order.type == OrderType.inbound ? "Nhập kho" : "Xuất kho"} · ${orderStatusLabel(order.status)}\n${order.createdAt == null ? "Chưa rõ ngày" : DateFormat("dd/MM/yyyy").format(order.createdAt!)}',
                ),
              ),
          ],
        ),
      ),
    ),
  );
  Future<void> export(WarehouseReport report, {required bool asPdf}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      const exporter = ReportExporter();
      if (asPdf) {
        // Printing downloads its Unicode font on first use. Failure is explicit.
        final font = await PdfGoogleFonts.notoSansRegular();
        final bytes = await exporter.pdf(
          report,
          range?.start,
          range?.end,
          font: font,
        );
        await Printing.sharePdf(bytes: bytes, filename: 'smart-wms-report.pdf');
      } else {
        final bytes = exporter.excel(report, range?.start, range?.end);
        await Share.shareXFiles([
          XFile.fromData(
            bytes,
            name: 'smart-wms-report.xlsx',
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ]);
      }
    } on Exception {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Không xuất được file. Kiểm tra quyền tải/chia sẻ; PDF cần tải font Unicode lần đầu.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
