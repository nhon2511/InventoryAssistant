import 'package:flutter/material.dart';

/// Full-screen pick verification screen for outbound orders.
///
/// Scans barcodes and verifies against the pick list.
/// Shows error modal (red) when barcode mismatches (PRD Story 2 AC).
class PickVerifyScreen extends StatelessWidget {
  const PickVerifyScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quét đối soát xuất kho')),
      body: Center(
        child: Text('Pick Verify for Order: $orderId'),
        // TODO: Implement pick verification scanner with error modal
      ),
    );
  }
}
