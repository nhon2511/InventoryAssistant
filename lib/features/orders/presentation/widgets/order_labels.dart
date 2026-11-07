import 'package:flutter/material.dart';
import 'package:smart_wms/core/enums/order_status.dart';

String orderStatusLabel(OrderStatus status) => switch (status) {
  OrderStatus.draft => 'Nháp',
  OrderStatus.confirmed => 'Đã duyệt',
  OrderStatus.processing => 'Đang xử lý',
  OrderStatus.completed => 'Hoàn tất',
  OrderStatus.cancelled => 'Đã hủy / từ chối',
};

class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({required this.status, super.key});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = status == OrderStatus.cancelled
        ? scheme.error
        : status == OrderStatus.draft
        ? scheme.onSurfaceVariant
        : scheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        orderStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
