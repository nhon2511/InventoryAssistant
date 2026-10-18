import 'package:flutter/material.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_list_screen.dart';

class OutboundListScreen extends StatelessWidget {
  const OutboundListScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const OrderListScreen(type: OrderType.outbound);
}
