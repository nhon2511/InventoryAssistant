import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraScanDialog extends StatefulWidget {
  const CameraScanDialog({super.key});
  static bool get supported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
  @override
  State<CameraScanDialog> createState() => _CameraScanDialogState();
}

class _CameraScanDialogState extends State<CameraScanDialog> {
  final controller = MobileScannerController();
  bool received = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    child: SizedBox(
      width: 600,
      height: 500,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Camera · đưa mã vạch vào khung'),
                ),
              ),
              IconButton(
                tooltip: 'Đóng camera',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: MobileScanner(
              controller: controller,
              errorBuilder: (context, error, child) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Không mở được camera. Kiểm tra quyền camera, thiết bị và HTTPS (hoặc localhost).',
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Quay lại nhập mã thủ công'),
                      ),
                    ],
                  ),
                ),
              ),
              onDetect: (capture) {
                if (received) return;
                final code = capture.barcodes
                    .map((b) => b.rawValue)
                    .whereType<String>()
                    .where((s) => s.trim().isNotEmpty)
                    .firstOrNull;
                if (code != null && mounted) {
                  received = true;
                  Navigator.pop(context, code);
                }
              },
            ),
          ),
        ],
      ),
    ),
  );
}
