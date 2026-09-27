import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/empty_state_widget.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/dashboard/domain/dashboard_snapshot.dart';
import 'package:smart_wms/features/dashboard/presentation/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Tổng quan kho')),
    body: ref.watch(dashboardProvider).when(
      loading: () => const AppLoadingWidget(message: 'Đang tải tổng quan...'),
      error: (error, _) => AppErrorWidget(message: error.toString(),
        onRetry: () => ref.invalidate(dashboardProvider)),
      data: (data) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          await ref.read(dashboardProvider.future);
        },
        child: ListView(padding: const EdgeInsets.all(AppTokens.lg), children: [
          Text('Hôm nay trong kho', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppTokens.lg),
          _Stats(data: data),
          const SizedBox(height: AppTokens.xl),
          _MovementChart(data: data),
          const SizedBox(height: AppTokens.xl),
          Text('Sản phẩm cần chú ý', style: Theme.of(context).textTheme.titleLarge),
          if (data.lowStockItems.isEmpty)
            const SizedBox(height: 100, child: EmptyStateWidget(message: 'Không có sản phẩm cần cảnh báo.'))
          else
            for (final item in data.lowStockItems)
              Card(child: ListTile(
                title: Text(item.productName ?? item.productId),
                subtitle: Text('Còn ${item.quantityAvailable} · ${item.locationLabel ?? item.locationId}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/products/${item.productId}'),
              )),
          const SizedBox(height: AppTokens.xl),
          Text('Hoạt động gần đây', style: Theme.of(context).textTheme.titleLarge),
          if (data.recentOrders.isEmpty)
            const SizedBox(height: 100, child: EmptyStateWidget(message: 'Chưa có phiếu nhập hoặc xuất.'))
          else
            for (final order in data.recentOrders)
              Card(child: ListTile(
                leading: Icon(order.type == OrderType.inbound ? Icons.input_rounded : Icons.output_rounded),
                title: Text(order.orderCode), subtitle: Text(order.status.dbValue),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go(order.type == OrderType.inbound
                    ? '/inbound/${order.id}' : '/outbound/${order.id}'),
              )),
        ]),
      ),
    ),
  );
}

class _Stats extends StatelessWidget {
  const _Stats({required this.data});
  final DashboardSnapshot data;
  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Sản phẩm', data.productCount, Icons.inventory_2_outlined, '/products'),
      ('Tổng tồn', data.totalStock, Icons.warehouse_outlined, '/products'),
      ('Sắp hết', data.lowStockCount, Icons.warning_amber_rounded, '/products?stock=low'),
      ('Hết hàng', data.outOfStockCount, Icons.remove_shopping_cart_outlined, '/products?stock=out'),
      ('Phiếu nhập', data.inboundCount, Icons.input_rounded, '/inbound'),
      ('Phiếu xuất', data.outboundCount, Icons.output_rounded, '/outbound'),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth >= 950 ? 3 : 2;
      final width = (constraints.maxWidth - AppTokens.md * (columns - 1)) / columns;
      return Wrap(spacing: AppTokens.md, runSpacing: AppTokens.md,
        children: [for (final card in cards) SizedBox(width: width, child: Card(
          child: InkWell(onTap: () => context.go(card.$4),
            child: Padding(padding: const EdgeInsets.all(AppTokens.lg),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(card.$3, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: AppTokens.md),
                Text('${card.$2}', style: Theme.of(context).textTheme.headlineSmall),
                Text(card.$1),
              ])),
          ),
        ))]);
    });
  }
}

class _MovementChart extends StatelessWidget {
  const _MovementChart({required this.data});
  final DashboardSnapshot data;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
    final maxCount = [...data.inboundByDay, ...data.outboundByDay, 1].reduce((a, b) => a > b ? a : b);
    return Card(child: Padding(padding: const EdgeInsets.all(AppTokens.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Phiếu nhập và xuất trong 7 ngày', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTokens.sm),
        const Text('Đếm số phiếu theo ngày'),
        const SizedBox(height: AppTokens.lg),
        SizedBox(height: 230, child: BarChart(BarChartData(
          maxY: maxCount.toDouble() + 1,
          borderData: FlBorderData(show: false), gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index > 6) return const SizedBox.shrink();
                final day = start.add(Duration(days: index));
                return Text('${day.day}/${day.month}', style: Theme.of(context).textTheme.labelSmall);
              })),
          ),
          barGroups: [for (var i = 0; i < 7; i++) BarChartGroupData(x: i, barsSpace: 3, barRods: [
            BarChartRodData(toY: data.inboundByDay[i].toDouble(), width: 11, color: scheme.primary),
            BarChartRodData(toY: data.outboundByDay[i].toDouble(), width: 11, color: scheme.tertiary),
          ])],
        ))),
        const SizedBox(height: AppTokens.sm),
        Wrap(spacing: AppTokens.lg, children: [
          Text('■ Nhập', style: TextStyle(color: scheme.primary)),
          Text('■ Xuất', style: TextStyle(color: scheme.tertiary)),
        ]),
      ]),
    ));
  }
}
