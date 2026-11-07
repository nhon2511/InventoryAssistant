import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_colors.dart';
import 'package:smart_wms/core/enums/stock_status.dart';
import 'package:smart_wms/features/reports/domain/entities/report_item.dart';

/// A table displaying all report items with safety stock status badges.
class ReportItemsTable extends StatelessWidget {
  const ReportItemsTable({required this.items, super.key});

  final List<ReportItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tổng hợp mặt hàng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                ),
                columnSpacing: 16,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('Mã SKU')),
                  DataColumn(label: Text('Tên sản phẩm')),
                  DataColumn(label: Text('Danh mục')),
                  DataColumn(
                    label: Text('Tồn kho'),
                    numeric: true,
                  ),
                  DataColumn(label: Text('Vị trí')),
                  DataColumn(label: Text('Trạng thái')),
                ],
                rows: items.map(_buildRow).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _buildRow(ReportItem item) {
    return DataRow(
      cells: [
        DataCell(Text(item.sku)),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              item.productName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(Text(item.category)),
        DataCell(Text('${item.totalOnHand}')),
        DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(
              item.locationLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        DataCell(_StatusBadge(status: item.status)),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final StockStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, bgColor) = switch (status) {
      StockStatus.inStock => (
          AppColors.inStock,
          AppColors.inStock.withValues(alpha: 0.12),
        ),
      StockStatus.lowStock => (
          AppColors.lowStock,
          AppColors.lowStock.withValues(alpha: 0.12),
        ),
      StockStatus.outOfStock => (
          AppColors.outOfStock,
          AppColors.outOfStock.withValues(alpha: 0.12),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
