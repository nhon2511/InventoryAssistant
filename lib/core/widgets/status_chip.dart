import 'package:flutter/material.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/core/enums/order_status.dart';

/// A status label whose color is defined by the shared design tokens.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  const StatusChip.inStock({super.key})
      : label = 'Còn hàng',
        color = AppTokens.inStock;

  const StatusChip.lowStock({super.key})
      : label = 'Sắp hết',
        color = AppTokens.lowStock;

  const StatusChip.outOfStock({super.key})
      : label = 'Hết hàng',
        color = AppTokens.outOfStock;

  factory StatusChip.order(OrderStatus status) => switch (status) {
    OrderStatus.draft => const StatusChip(label: 'Nháp', color: AppTokens.draft),
    OrderStatus.confirmed => const StatusChip(label: 'Đã xác nhận', color: AppTokens.confirmed),
    OrderStatus.processing => const StatusChip(label: 'Đang xử lý', color: AppTokens.pending),
    OrderStatus.completed => const StatusChip(label: 'Hoàn tất', color: AppTokens.completed),
    OrderStatus.cancelled => const StatusChip(label: 'Đã hủy', color: AppTokens.outOfStock),
  };

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
        backgroundColor: color.withValues(alpha: 0.12),
        side: BorderSide(color: color.withValues(alpha: 0.25)),
        visualDensity: VisualDensity.compact,
      );
}

class QuantityBadge extends StatelessWidget {
  const QuantityBadge({required this.quantity, super.key});
  final int quantity;

  @override
  Widget build(BuildContext context) => Badge(
        label: Text('$quantity'),
        backgroundColor: quantity <= 0
            ? AppTokens.outOfStock
            : AppTokens.inStock,
      );
}

class ExpiryWarningChip extends StatelessWidget {
  const ExpiryWarningChip({required this.expiryDate, super.key});
  final DateTime expiryDate;

  @override
  Widget build(BuildContext context) {
    final days = expiryDate.difference(DateTime.now()).inDays;
    if (days >= 30) return const SizedBox.shrink();
    final expired = days < 0;
    return StatusChip(
      label: expired ? 'Đã hết hạn' : 'Sắp hết hạn',
      color: expired ? AppTokens.expired : AppTokens.expiring,
    );
  }
}
