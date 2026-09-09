import 'package:flutter/material.dart';

/// Screen displaying details of a single inbound order.
class InboundDetailScreen extends StatelessWidget {
  const InboundDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu nhập')),
      body: Center(
        child: Text('Order ID: $orderId'),
        // TODO: Implement inbound order detail with line items
      ),
    );
  }
}
