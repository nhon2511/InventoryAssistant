import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_wms/features/reports/domain/entities/report_item.dart';

/// Displays a bar chart showing stock quantities for the top products.
///
/// Shows the highest-stock products and allows changing the number of rows.
class InventoryChartWidget extends StatefulWidget {
  const InventoryChartWidget({required this.items, super.key});

  final List<ReportItem> items;

  @override
  State<InventoryChartWidget> createState() => _InventoryChartWidgetState();
}

enum _ProductCount { seven, twelve }

class _InventoryChartWidgetState extends State<InventoryChartWidget> {
  _ProductCount _productCount = _ProductCount.seven;

  @override
  Widget build(BuildContext context) {
    final displayItems = _getDisplayItems();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final title = Text(
                  'Tồn khả dụng theo mặt hàng',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                );
                final productCount = SegmentedButton<_ProductCount>(
                  segments: const [
                    ButtonSegment(
                      value: _ProductCount.seven,
                      label: Text('7 mặt hàng'),
                    ),
                    ButtonSegment(
                      value: _ProductCount.twelve,
                      label: Text('12 mặt hàng'),
                    ),
                  ],
                  selected: {_productCount},
                  onSelectionChanged: (selected) {
                    setState(() => _productCount = selected.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                );

                if (constraints.maxWidth < 900) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 8), productCount],
                  );
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [title, productCount],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Xếp theo số lượng thực có, từ cao xuống thấp.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            _buildLegend(),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: displayItems.isEmpty
                  ? const Center(child: Text('Không có dữ liệu để hiển thị'))
                  : BarChart(
                      _buildChartData(displayItems),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<ReportItem> _getDisplayItems() {
    final sorted = List<ReportItem>.from(widget.items)
      ..sort((a, b) => b.totalOnHand.compareTo(a.totalOnHand));
    final count = _productCount == _ProductCount.seven ? 7 : 12;
    return sorted.take(min(count, sorted.length)).toList();
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        _legendDot(Theme.of(context).colorScheme.primary, 'Thực có'),
        _legendDot(Theme.of(context).colorScheme.outline, 'Giữ chỗ'),
        _legendDot(Theme.of(context).colorScheme.tertiary, 'Khả dụng'),
      ],
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  BarChartData _buildChartData(List<ReportItem> items) {
    final maxY = items.fold<int>(
      0,
      (maxVal, item) => max(maxVal, item.totalOnHand),
    );
    final chartMaxY = max(1, (maxY * 1.2).ceil());

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: chartMaxY.toDouble(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = items[groupIndex];
            final labels = ['Thực có', 'Giữ chỗ', 'Khả dụng'];
            return BarTooltipItem(
              '${item.productName}\n${labels[rodIndex]}: ${rod.toY.toInt()}',
              TextStyle(
                color: Theme.of(context).colorScheme.onInverseSurface,
                fontSize: 12,
              ),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= items.length) {
                return const SizedBox.shrink();
              }
              final name = items[index].productName;
              final display = name.length > 6
                  ? '${name.substring(0, 6)}...'
                  : name;
              return SideTitleWidget(
                meta: meta,
                space: 4,
                child: Text(
                  display,
                  style: const TextStyle(fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        drawVerticalLine: false,
        horizontalInterval: max(1, chartMaxY / 5).toDouble(),
      ),
      barGroups: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.totalOnHand.toDouble(),
              color: Theme.of(context).colorScheme.primary,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: item.totalReserved.toDouble(),
              color: Theme.of(context).colorScheme.outline,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: item.totalAvailable.toDouble(),
              color: Theme.of(context).colorScheme.tertiary,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}
