import 'package:flutter/material.dart';

/// Full-screen batch barcode scanning screen.
///
/// Uses `mobile_scanner` for continuous scanning with
/// haptic feedback and beep on each successful scan.
class BatchScanScreen extends StatelessWidget {
  const BatchScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quét mã vạch hàng loạt'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () {
              // TODO: Toggle flashlight
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('TODO: Implement MobileScanner widget'),
        // TODO: Integrate mobile_scanner with BatchScannerController
      ),
    );
  }
}
