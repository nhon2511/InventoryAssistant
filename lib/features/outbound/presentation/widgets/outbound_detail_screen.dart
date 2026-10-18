import 'package:flutter/material.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_detail_screen.dart';

class OutboundDetailScreen extends StatelessWidget {
  const OutboundDetailScreen({required this.orderId, super.key});
  final String orderId;
  @override
  Widget build(BuildContext context) =>
      OrderDetailScreen(type: OrderType.outbound, orderId: orderId);
}
