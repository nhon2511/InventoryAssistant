import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_realtime_controller.dart';
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
          value: ref.watch(inventoryRealtimeProvider),
          onRetry: () => ref.invalidate(inventoryRealtimeProvider),
          builder: (items) {
            final report = WarehouseReport(
              products: products,
              locations: const [],
              stock: items,
              orders: const [],
              loadedAt: DateTime.now(),
            );
            final distinct = items
                .where((s) => s.quantityOnHand > 0)
                .map((s) => s.productId)
                .toSet()
                .length;
            final units = products.map((p) => p.unit).toSet().toList()..sort();
            final unit = units.contains(selectedUnit)
                ? selectedUnit
                : units.firstOrNull;
            final shown = products
                .where((p) => p.unit == unit)
                .take(5)
                .toList();
            final maxValue = shown.fold<double>(
              1,
              (max, p) => math.max(max, report.availableFor(p.id).toDouble()),
            );
            return ListView(
              padding: workspacePadding(context),
              children: [
                WorkspaceHeader(
                  title: manager ? 'Điều hành kho' : 'Công việc của tôi',
                  description:
                      'Theo dõi tồn kho và ưu tiên công việc cần xử lý.',
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
                          ..invalidate(inventoryRealtimeProvider)
                          ..invalidate(productControllerProvider);
                      },
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    _Metric(
                      label: 'Sản phẩm có tồn',
                      value: '$distinct',
                      unit: 'SKU',
                      icon: Icons.inventory_2_outlined,
                    ),
                    _Metric(
                      label: 'Dưới mức an toàn',
                      unit: 'SKU',
                      icon: Icons.warning_amber_outlined,
                      value: '${report.lowStock.length}',
                    ),
                    for (final entry in report.onHandByUnit.entries)
                      _Metric(
                        label: 'Tồn thực có',
                        unit: entry.key,
                        icon: Icons.warehouse_outlined,
                        value: '${entry.value}',
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 32),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/outbound/new'),
                      icon: const Icon(Icons.output),
                      label: const Text('Tạo phiếu xuất'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/reports'),
                      icon: const Icon(Icons.assessment_outlined),
                      label: const Text('Xem báo cáo'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/batch-scan'),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Tra mã hàng'),
                    ),
                  ],
                ),
                const Divider(height: 32),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final alerts = WorkspacePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Phiếu nháp cần xử lý',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          for (final type in OrderType.values)
                            AsyncPanel(
                              value: ref.watch(ordersProvider(type)),
                              onRetry: () =>
                                  ref.invalidate(ordersProvider(type)),
                              builder: (orders) {
                                final count = orders
                                    .where((o) => o.status == OrderStatus.draft)
                                    .length;
                                return ListTile(
                                  title: Text(
                                    '${type == OrderType.inbound ? "Nhập" : "Xuất"} · $count phiếu nháp',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => context.go(
                                    type == OrderType.inbound
                                        ? '/inbound'
                                        : '/outbound',
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 24),
                          Text(
                            'Cảnh báo tồn an toàn',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (report.lowStock.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Không có SKU dưới mức an toàn trong dữ liệu đã nhận.',
                              ),
                            ),
                          for (final p in report.lowStock)
                            ListTile(
                              leading: const Icon(Icons.warning_amber),
                              title: Text(p.name),
                              subtitle: Text(
                                'Khả dụng ${report.availableFor(p.id)} / an toàn ${p.minSafetyStock} ${p.unit}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.go('/products/${p.id}'),
                            ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                    final chart = WorkspacePanel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Khả dụng theo sản phẩm',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (units.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: SizedBox(
                                  width: 200,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: unit,
                                    decoration: const InputDecoration(
                                      labelText: 'Đơn vị biểu đồ',
                                    ),
                                    items: units
                                        .map(
                                          (value) => DropdownMenuItem(
                                            value: value,
                                            child: Text(value),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) =>
                                        setState(() => selectedUnit = value),
                                  ),
                                ),
                              ),
                            ),
                          if (shown.isNotEmpty)
                            Semantics(
                              label: 'Biểu đồ khả dụng. Số liệu và đơn vị từng SKU ở danh sách bên dưới.',
                              child: SizedBox(
                                height: 210,
                                child: ExcludeSemantics(
                                  child: BarChart(
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                        ? Duration.zero
                                        : const Duration(milliseconds: 200),
                                    BarChartData(
                                      maxY: maxValue * 1.2,
                                      minY: 0,
                                      titlesData: FlTitlesData(
                                        topTitles: const AxisTitles(),
                                        rightTitles: const AxisTitles(),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 40,
                                            getTitlesWidget: (value, meta) =>
                                                Text(
                                                  value.toInt().toString(),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                          ),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 32,
                                            getTitlesWidget: (value, meta) {
                                              final index = value.toInt();
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 8,
                                                ),
                                                child: Text(
                                                  index >= 0 &&
                                                          index < shown.length
                                                      ? shown[index].sku
                                                      : '',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      barTouchData: BarTouchData(
                                        enabled: true,
                                        touchTooltipData: BarTouchTooltipData(
                                          getTooltipItem:
                                              (
                                                group,
                                                groupIndex,
                                                rod,
                                                rodIndex,
                                              ) => BarTooltipItem(
                                                '${shown[group.x].sku}\n${report.availableFor(shown[group.x].id)} $unit',
                                                const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                        ),
                                      ),
                                      barGroups: [
                                        for (var i = 0; i < shown.length; i++)
                                          BarChartGroupData(
                                            x: i,
                                            barRods: [
                                              BarChartRodData(
                                                toY: math
                                                    .max(
                                                      0,
                                                      report.availableFor(
                                                        shown[i].id,
                                                      ),
                                                    )
                                                    .toDouble(),
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                                width: 28,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (products.isEmpty)
                            const Text('Chưa có sản phẩm để vẽ biểu đồ.'),
                          for (final p in shown)
                            ListTile(
                              title: Text(p.name),
                              subtitle: Text(p.sku),
                              trailing: Text(
                                '${report.availableFor(p.id)} ${p.unit}',
                              ),
                              onTap: () => context.go('/products/${p.id}'),
                            ),
                          const Text(
                            'Tối đa 5 sản phẩm cùng đơn vị. Khả dụng = thực có − giữ chỗ. Giá trị âm hiển thị trong danh sách.',
                          ),
                        ],
                      ),
                    );
                    return constraints.maxWidth >= 960
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: chart),
                              const SizedBox(width: 24),
                              Expanded(flex: 2, child: alerts),
                            ],
                          )
                        : Column(
                            children: [
                              alerts,
                              const SizedBox(height: 24),
                              chart,
                            ],
                          );
                  },
                ),
                const Divider(height: 32),
                Text(
                  'Tồn kho theo vị trí',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (items.isEmpty) const Text('Chưa có bản ghi tồn kho.'),
                for (final item in items)
                  ListTile(
                    title: Text(item.productName ?? item.productId),
                    subtitle: Text(
                      '${item.locationLabel ?? item.locationId}\nThực có ${item.quantityOnHand} · Giữ chỗ ${item.quantityReserved} · Khả dụng ${item.quantityAvailable}',
                    ),
                    isThreeLine: true,
                    onTap: () => context.go('/products/${item.productId}'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width < 600
        ? (MediaQuery.sizeOf(context).width - 48) / 2
        : 190,
    child: WorkspacePanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 12),
          Text(label),
          const SizedBox(height: 8),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(unit),
            ],
          ),
        ],
      ),
    ),
  );
}
