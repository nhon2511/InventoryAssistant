import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_colors.dart';
import 'package:smart_wms/features/reports/domain/entities/inventory_summary.dart';

/// Row of summary statistic cards for the reports screen.
class InventorySummaryCards extends StatelessWidget {
  const InventorySummaryCards({required this.summary, super.key});

  final InventorySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Tổng mặt hàng',
                value: '${summary.totalProducts}',
                icon: Icons.inventory_2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Tổng tồn kho',
                value: '${summary.totalStockQuantity}',
                icon: Icons.warehouse,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: 'Sắp hết hàng',
                value: '${summary.lowStockCount}',
                icon: Icons.warning_amber_rounded,
                color: AppColors.lowStock,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: 'Hết hàng',
                value: '${summary.outOfStockCount}',
                icon: Icons.error_outline_rounded,
                color: AppColors.outOfStock,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
