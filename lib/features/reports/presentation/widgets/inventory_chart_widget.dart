import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_colors.dart';
import 'package:smart_wms/features/reports/domain/entities/report_item.dart';

/// Displays a bar chart showing stock quantities for the top products.
///
/// Supports toggling between "Tuần" (weekly) and "Tháng" (monthly) views.
class InventoryChartWidget extends StatefulWidget {
  const InventoryChartWidget({required this.items, super.key});

  final List<ReportItem> items;

  @override
  State<InventoryChartWidget> createState() => _InventoryChartWidgetState();
}

enum _ChartPeriod { week, month }

class _InventoryChartWidgetState extends State<InventoryChartWidget> {
  _ChartPeriod _period = _ChartPeriod.week;

  @override
  Widget build(BuildContext context) {
    final displayItems = _getDisplayItems();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biến động tồn kho',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SegmentedButton<_ChartPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: _ChartPeriod.week,
                      label: Text('Tuần'),
                    ),
                    ButtonSegment(
                      value: _ChartPeriod.month,
                      label: Text('Tháng'),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (selected) {
                    setState(() => _period = selected.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: displayItems.isEmpty
                  ? const Center(
                      child: Text('Không có dữ liệu để hiển thị'),
                    )
                  : BarChart(_buildChartData(displayItems)),
            ),
          ],
        ),
      ),
    );
  }

  List<ReportItem> _getDisplayItems() {
    final sorted = List<ReportItem>.from(widget.items)
      ..sort((a, b) => b.totalOnHand.compareTo(a.totalOnHand));
    final count = _period == _ChartPeriod.week ? 7 : 12;
    return sorted.take(min(count, sorted.length)).toList();
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendDot(AppColors.inStock, 'Tồn kho'),
        const SizedBox(width: 16),
        _legendDot(AppColors.lowStock, 'Đã giữ'),
        const SizedBox(width: 16),
        _legendDot(AppColors.info, 'Khả dụng'),
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

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: (maxY * 1.2).ceilToDouble(),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final item = items[groupIndex];
            final labels = ['Tồn kho', 'Đã giữ', 'Khả dụng'];
            return BarTooltipItem(
              '${item.productName}\n${labels[rodIndex]}: ${rod.toY.toInt()}',
              const TextStyle(color: Colors.white, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
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
              final display =
                  name.length > 6 ? '${name.substring(0, 6)}...' : name;
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
        show: true,
        drawVerticalLine: false,
        horizontalInterval: max(1, maxY / 5).toDouble(),
      ),
      barGroups: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: item.totalOnHand.toDouble(),
              color: AppColors.inStock,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: item.totalReserved.toDouble(),
              color: AppColors.lowStock,
              width: 8,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
            BarChartRodData(
              toY: item.totalAvailable.toDouble(),
              color: AppColors.info,
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

