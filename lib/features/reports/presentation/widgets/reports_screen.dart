import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/reports/presentation/controllers/reports_controller.dart';
import 'package:smart_wms/features/reports/presentation/widgets/inventory_chart_widget.dart';
import 'package:smart_wms/features/reports/presentation/widgets/inventory_summary_cards.dart';
import 'package:smart_wms/features/reports/presentation/widgets/report_items_table.dart';

/// Main reports screen showing inventory statistics, charts, and data table.
///
/// Provides export actions for Excel and PDF from the AppBar.
class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(reportsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo kho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Xuất Excel',
            onPressed: () => _exportExcel(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'Xuất PDF',
            onPressed: () => _exportPdf(context, ref),
          ),
          PopupMenuButton<_ExportAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) {
              switch (action) {
                case _ExportAction.sharePdf:
                  _sharePdf(context, ref);
                case _ExportAction.refresh:
                  ref
                      .read(reportsControllerProvider.notifier)
                      .refresh();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: _ExportAction.sharePdf,
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Chia sẻ PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _ExportAction.refresh,
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Làm mới'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: reportsAsync.when(
        loading: () => const AppLoadingWidget(
          message: 'Đang tải dữ liệu báo cáo...',
        ),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(reportsControllerProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () =>
              ref.read(reportsControllerProvider.notifier).refresh(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InventorySummaryCards(summary: summary),
                const SizedBox(height: 16),
                InventoryChartWidget(items: summary.items),
                const SizedBox(height: 16),
                ReportItemsTable(items: summary.items),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportExcel(BuildContext context, WidgetRef ref) async {
    _showSnackBar(context, 'Đang tạo file Excel...');
    final message = await ref
        .read(reportsControllerProvider.notifier)
        .exportExcel();
    if (context.mounted) _showSnackBar(context, message);
  }

  Future<void> _exportPdf(BuildContext context, WidgetRef ref) async {
    _showSnackBar(context, 'Đang tạo PDF...');
    final message = await ref
        .read(reportsControllerProvider.notifier)
        .exportPdf();
    if (context.mounted) _showSnackBar(context, message);
  }

  Future<void> _sharePdf(BuildContext context, WidgetRef ref) async {
    _showSnackBar(context, 'Đang chuẩn bị PDF...');
    final message = await ref
        .read(reportsControllerProvider.notifier)
        .sharePdf();
    if (context.mounted) _showSnackBar(context, message);
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ExportAction { sharePdf, refresh }
