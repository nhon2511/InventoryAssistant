import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_realtime_controller.dart';

/// Dashboard screen showing real-time stock overview.
///
/// This is the main home screen for managers (Web Dashboard).
class StockOverviewScreen extends ConsumerWidget {
  const StockOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventoryAsync = ref.watch(inventoryRealtimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tổng quan kho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications / alerts
            },
          ),
        ],
      ),
      body: inventoryAsync.when(
        loading: () => const AppLoadingWidget(message: 'Đang tải dữ liệu kho...'),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(inventoryRealtimeProvider),
        ),
        data: (items) {
          final totalItems = items.length;
          final totalOnHand = items.fold<int>(
            0,
            (sum, item) => sum + item.quantityOnHand,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'Tổng mặt hàng',
                        value: '$totalItems',
                        icon: Icons.inventory_2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'Tổng tồn kho',
                        value: '$totalOnHand',
                        icon: Icons.warehouse,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Chi tiết tồn kho (Realtime)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                // TODO: Add fl_chart widgets and stock list
                ...items.take(20).map(
                      (item) => Card(
                        child: ListTile(
                          title: Text(item.productName ?? item.productId),
                          subtitle: Text(
                            'Tồn: ${item.quantityOnHand} | '
                            'Đã giữ: ${item.quantityReserved}',
                          ),
                          trailing: Text(
                            '${item.quantityAvailable}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: item.quantityAvailable <= 0
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
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
            Icon(icon, color: color, size: 32),
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
