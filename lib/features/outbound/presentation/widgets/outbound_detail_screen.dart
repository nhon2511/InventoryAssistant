import 'package:flutter/material.dart';

/// Screen displaying details of a single outbound order.
class OutboundDetailScreen extends StatelessWidget {
  const OutboundDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu xuất')),
      body: Center(
        child: Text('Order ID: $orderId'),
        // TODO: Implement outbound order detail with pick list
      ),
    );
  }
}
