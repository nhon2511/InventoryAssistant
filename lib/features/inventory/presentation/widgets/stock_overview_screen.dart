import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/preview/preview_mode.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:smart_wms/features/reports/domain/entities/warehouse_report.dart';

class StockOverviewScreen extends ConsumerStatefulWidget {
  const StockOverviewScreen({super.key});

  @override
  ConsumerState<StockOverviewScreen> createState() =>
      _StockOverviewScreenState();
}

class _StockOverviewScreenState extends ConsumerState<StockOverviewScreen> {
  String? selectedUnit;

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final manager =
        auth is AuthAuthenticated && auth.profile.role.isManagerOrAbove;

    return Scaffold(
      body: AsyncPanel(
        value: ref.watch(productControllerProvider),
        onRetry: () => ref.invalidate(productControllerProvider),
        builder: (products) => AsyncPanel(
          value: ref.watch(stockOverviewItemsProvider),
          onRetry: () => ref.invalidate(stockOverviewItemsProvider),
          builder: (items) {
            final report = WarehouseReport(
              products: products,
              locations: const [],
              stock: items,
              orders: const [],
              loadedAt: DateTime.now(),
            );
            final distinct = items
                .where((item) => item.quantityOnHand > 0)
                .map((item) => item.productId)
                .toSet()
                .length;
            final units =
                products.map((product) => product.unit).toSet().toList()
                  ..sort();
            final unit = units.contains(selectedUnit)
                ? selectedUnit
                : units.firstOrNull;
            final shown = products
                .where((product) => product.unit == unit)
                .take(5)
                .toList();
            final maxValue = shown.fold<double>(
              1,
              (max, product) =>
                  math.max(max, report.availableFor(product.id).toDouble()),
            );

            return WorkspaceContent(
              child: ListView(
                padding: workspacePadding(context),
                children: [
                  WorkspaceHeader(
                    title: manager ? 'Điều hành kho' : 'Công việc của tôi',
                    description: 'Theo dõi tồn kho và ưu tiên việc cần xử lý.',
                    actions: [
                      FilledButton.icon(
                        onPressed: () => context.go('/inbound/new'),
                        icon: const Icon(Icons.add),
                        label: const Text('Tạo phiếu nhập'),
                      ),
                      IconButton(
                        tooltip: 'Tải lại tồn kho',
                        onPressed: () {
                          ref
                            ..invalidate(stockOverviewItemsProvider)
                            ..invalidate(productControllerProvider);
                        },
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                  Text(
                    ref.watch(frontendPreviewProvider)
                        ? 'Dữ liệu mẫu trong bộ nhớ. Tải lại để xem snapshot mẫu mới.'
                        : 'Tồn kho tải từ NestJS. Realtime chưa được xác minh; dùng Tải lại tồn kho để lấy snapshot mới.',
                  ),
                  _OverviewSummary(
                    distinctProducts: distinct,
                    lowStockProducts: report.lowStock.length,
                    stockByUnit: report.onHandByUnit.entries.toList(),
                  ),
                  const SizedBox(height: 24),
                  _QuickActions(
                    onOutbound: () => context.go('/outbound/new'),
                    onReports: () => context.go('/reports'),
                    onLookup: () => context.push('/batch-scan'),
                  ),
                  const SizedBox(height: 28),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final alerts = _AlertsPanel(
                        report: report,
                        onOrderTap: (type) => context.go(
                          type == OrderType.inbound ? '/inbound' : '/outbound',
                        ),
                        onProductTap: (productId) =>
                            context.go('/products/$productId'),
                        orders: (type) => ref.watch(ordersProvider(type)),
                        retryOrders: (type) =>
                            ref.invalidate(ordersProvider(type)),
                      );
                      final chart = _AvailabilityPanel(
                        report: report,
                        products: products,
                        shown: shown,
                        units: units,
                        unit: unit,
                        maxValue: maxValue,
                        onUnitChanged: (value) =>
                            setState(() => selectedUnit = value),
                        onProductTap: (productId) =>
                            context.go('/products/$productId'),
                      );

                      if (constraints.maxWidth >= 1040) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: chart),
                            const SizedBox(width: 20),
                            Expanded(flex: 5, child: alerts),
                          ],
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [alerts, const SizedBox(height: 20), chart],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _StockLocationList(
                    items: items,
                    onProductTap: (productId) =>
                        context.go('/products/$productId'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.attention = false,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final bool attention;
}

class _OverviewSummary extends StatelessWidget {
  const _OverviewSummary({
    required this.distinctProducts,
    required this.lowStockProducts,
    required this.stockByUnit,
  });

  final int distinctProducts;
  final int lowStockProducts;
  final List<MapEntry<String, int>> stockByUnit;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final products = _MetricCard(
        metric: _MetricData(
          label: 'Sản phẩm đang có tồn',
          value: '$distinctProducts',
          unit: 'SKU',
          icon: Icons.inventory_2_outlined,
        ),
      );
      final lowStock = _MetricCard(
        metric: _MetricData(
          label: 'Dưới mức an toàn',
          value: '$lowStockProducts',
          unit: 'SKU',
          icon: Icons.warning_amber_outlined,
          attention: lowStockProducts > 0,
        ),
      );
      final stock = _StockSummaryPanel(stockByUnit: stockByUnit);

      if (constraints.maxWidth >= 900) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: products),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: lowStock),
            const SizedBox(width: 12),
            Expanded(flex: 5, child: stock),
          ],
        );
      }

      final metricCards = constraints.maxWidth >= 360
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: products),
                const SizedBox(width: 12),
                Expanded(child: lowStock),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [products, const SizedBox(height: 12), lowStock],
            );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [metricCards, const SizedBox(height: 12), stock],
      );
    },
  );
}

class _StockSummaryPanel extends StatelessWidget {
  const _StockSummaryPanel({required this.stockByUnit});

  final List<MapEntry<String, int>> stockByUnit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Tồn thực có',
                style: textTheme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              if (stockByUnit.isEmpty)
                Text(
                  'Chưa có số lượng tồn.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                )
              else
                Wrap(
                  spacing: 28,
                  runSpacing: 12,
                  children: [
                    for (final entry in stockByUnit)
                      ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 76),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${entry.value}',
                              style: textTheme.headlineSmall?.copyWith(
                                color: scheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                            Text(
                              entry.key,
                              style: textTheme.bodySmall?.copyWith(
                                color: scheme.onPrimaryContainer.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final _MetricData metric;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ink = metric.attention ? scheme.secondary : scheme.primary;

    return WorkspacePanel(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(metric.icon, color: ink, size: 19),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.label,
                    style: Theme.of(context).textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  metric.value,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: metric.attention ? ink : null,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(metric.unit, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({
    required this.onOutbound,
    required this.onReports,
    required this.onLookup,
  });

  final VoidCallback onOutbound;
  final VoidCallback onReports;
  final VoidCallback onLookup;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        onPressed: onOutbound,
        icon: const Icon(Icons.output),
        label: const Text('Tạo phiếu xuất'),
      ),
      OutlinedButton.icon(
        onPressed: onReports,
        icon: const Icon(Icons.assessment_outlined),
        label: const Text('Xem báo cáo'),
      ),
      OutlinedButton.icon(
        onPressed: onLookup,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Tra mã hàng'),
      ),
    ],
  );
}

class _AlertsPanel extends StatelessWidget {
  const _AlertsPanel({
    required this.report,
    required this.onOrderTap,
    required this.onProductTap,
    required this.orders,
    required this.retryOrders,
  });

  final WarehouseReport report;
  final ValueChanged<OrderType> onOrderTap;
  final ValueChanged<String> onProductTap;
  final AsyncValue<List<WarehouseOrder>> Function(OrderType) orders;
  final ValueChanged<OrderType> retryOrders;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lowStock = report.lowStock;

    return WorkspacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cần xử lý',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Phiếu nháp và mức tồn cần theo dõi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (lowStock.isNotEmpty)
                Semantics(
                  label: '${lowStock.length} SKU dưới mức an toàn',
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 36),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${lowStock.length}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: scheme.onSecondaryContainer,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          for (final type in OrderType.values)
            AsyncPanel(
              value: orders(type),
              onRetry: () => retryOrders(type),
              builder: (orderList) {
                final count = orderList
                    .where((order) => order.status == OrderStatus.draft)
                    .length;
                final inbound = type == OrderType.inbound;
                return _QueueRow(
                  icon: inbound ? Icons.move_to_inbox_outlined : Icons.outbox,
                  title: inbound ? 'Phiếu nhập nháp' : 'Phiếu xuất nháp',
                  count: count,
                  onTap: () => onOrderTap(type),
                );
              },
            ),
          const SizedBox(height: 14),
          Divider(color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  lowStock.isEmpty
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: lowStock.isEmpty ? scheme.tertiary : scheme.secondary,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lowStock.isEmpty
                        ? 'Tồn kho trong ngưỡng an toàn'
                        : 'Sản phẩm dưới mức an toàn',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
          ),
          if (lowStock.isEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 27, bottom: 8),
              child: Text(
                'Không có SKU cần bổ sung trong dữ liệu đã nhận.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            )
          else
            for (final product in lowStock)
              _LowStockRow(
                name: product.name,
                available: report.availableFor(product.id),
                minimum: product.minSafetyStock,
                unit: product.unit,
                onTap: () => onProductTap(product.id),
              ),
        ],
      ),
    );
  }
}

class _QueueRow extends StatelessWidget {
  const _QueueRow({
    required this.icon,
    required this.title,
    required this.count,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$title, $count phiếu',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Icon(icon, color: scheme.primary, size: 19),
              const SizedBox(width: 10),
              Expanded(child: Text(title)),
              Text(
                '$count',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: count > 0 ? scheme.secondary : scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 5),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LowStockRow extends StatelessWidget {
  const _LowStockRow({
    required this.name,
    required this.available,
    required this.minimum,
    required this.unit,
    required this.onTap,
  });

  final String name;
  final int available;
  final int minimum;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            children: [
              Expanded(
                child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$available $unit',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: scheme.secondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'Mức an toàn $minimum',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvailabilityPanel extends StatelessWidget {
  const _AvailabilityPanel({
    required this.report,
    required this.products,
    required this.shown,
    required this.units,
    required this.unit,
    required this.maxValue,
    required this.onUnitChanged,
    required this.onProductTap,
  });

  final WarehouseReport report;
  final List<Product> products;
  final List<Product> shown;
  final List<String> units;
  final String? unit;
  final double maxValue;
  final ValueChanged<String?> onUnitChanged;
  final ValueChanged<String> onProductTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final interval = _chartInterval(maxValue);
    final chartMaxY = ((maxValue / interval).floor() + 1) * interval;

    return WorkspacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tồn khả dụng', style: textTheme.titleLarge),
          const SizedBox(height: 3),
          Text('Tối đa 5 SKU theo đơn vị tính', style: textTheme.bodySmall),
          if (units.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: SizedBox(
                width: 210,
                child: DropdownButtonFormField<String>(
                  initialValue: unit,
                  decoration: const InputDecoration(labelText: 'Đơn vị tính'),
                  items: units
                      .map(
                        (value) =>
                            DropdownMenuItem(value: value, child: Text(value)),
                      )
                      .toList(),
                  onChanged: onUnitChanged,
                ),
              ),
            ),
          if (shown.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (shown.length == 1)
              _SingleAvailability(
                product: shown.single,
                available: report.availableFor(shown.single.id),
                onTap: () => onProductTap(shown.single.id),
              )
            else
              Semantics(
                label: 'Biểu đồ tồn khả dụng theo SKU. Tên SKU và số lượng được nêu trong danh sách bên dưới.',
                child: SizedBox(
                  height: 204,
                  child: ExcludeSemantics(
                    child: BarChart(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      BarChartData(
                        maxY: chartMaxY,
                        minY: 0,
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: scheme.outlineVariant.withValues(alpha: 0.7),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(),
                          rightTitles: const AxisTitles(),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 38,
                              interval: interval,
                              getTitlesWidget: (value, meta) => SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  value.toInt().toString(),
                                  style: textTheme.bodySmall,
                                ),
                              ),
                            ),
                          ),
                          bottomTitles: const AxisTitles(),
                        ),
                        borderData: FlBorderData(show: false),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final product = shown[group.x];
                              return BarTooltipItem(
                                '${product.sku}\n${report.availableFor(product.id)} $unit',
                                TextStyle(
                                  color: scheme.onInverseSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        barGroups: [
                          for (var index = 0; index < shown.length; index++)
                            BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: math
                                      .max(
                                        0,
                                        report.availableFor(shown[index].id),
                                      )
                                      .toDouble(),
                                  color: scheme.primary,
                                  width: shown.length > 4 ? 20 : 28,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (shown.length > 1) ...[
              const SizedBox(height: 8),
              for (final product in shown)
                _AvailabilityRow(
                  name: product.name,
                  available: report.availableFor(product.id),
                  unit: product.unit,
                  onTap: () => onProductTap(product.id),
                ),
            ],
          ] else if (products.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Chưa có sản phẩm để hiển thị.',
                style: textTheme.bodyMedium,
              ),
            ),
          const SizedBox(height: 6),
          Text(
            'Khả dụng = thực có − giữ chỗ. Số âm vẫn được giữ trong danh sách.',
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  double _chartInterval(double maxValue) {
    if (maxValue <= 4) return 1;
    if (maxValue <= 20) return 5;
    final magnitude = math.pow(
      10,
      (math.log(maxValue / 4) / math.ln10).floor(),
    );
    return (magnitude * (maxValue / (4 * magnitude)).ceil()).toDouble();
  }
}

class _SingleAvailability extends StatelessWidget {
  const _SingleAvailability({
    required this.product,
    required this.available,
    required this.onTap,
  });

  final Product product;
  final int available;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: Semantics(
        button: true,
        label:
            '${product.name}, mã ${product.sku}, còn $available ${product.unit}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(product.sku, style: textTheme.bodySmall),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$available',
                      style: textTheme.headlineMedium?.copyWith(
                        color: available < 0 ? scheme.error : scheme.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(product.unit, style: textTheme.bodySmall),
                  ],
                ),
                const SizedBox(width: 6),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityRow extends StatelessWidget {
  const _AvailabilityRow({
    required this.name,
    required this.available,
    required this.unit,
    required this.onTap,
  });

  final String name;
  final int available;
  final String unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 12),
              Text(
                '$available $unit',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: available < 0 ? scheme.error : scheme.onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockLocationList extends StatelessWidget {
  const _StockLocationList({required this.items, required this.onProductTap});

  final List<InventoryItem> items;
  final ValueChanged<String> onProductTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tồn kho theo vị trí',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          WorkspacePanel(
            child: Text(
              'Chưa có bản ghi tồn kho.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          )
        else
          WorkspacePanel(
            child: Column(
              children: [
                for (final (index, item) in items.indexed) ...[
                  if (index > 0) Divider(color: scheme.outlineVariant),
                  Semantics(
                    button: true,
                    child: InkWell(
                      onTap: () => onProductTap(item.productId),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? item.productId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item.locationLabel ?? item.locationId,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Wrap(
                                alignment: WrapAlignment.end,
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  _Quantity(
                                    label: 'Thực có',
                                    value: item.quantityOnHand,
                                  ),
                                  _Quantity(
                                    label: 'Giữ chỗ',
                                    value: item.quantityReserved,
                                  ),
                                  _Quantity(
                                    label: 'Khả dụng',
                                    value: item.quantityAvailable,
                                    strong: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final int value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      Text(
        '$value',
        style:
            (strong
                    ? Theme.of(context).textTheme.titleSmall
                    : Theme.of(context).textTheme.bodyMedium)
                ?.copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    ],
  );
}
