import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_wms/features/outbound/domain/entities/pick_list_item.dart';
import 'package:smart_wms/features/outbound/domain/usecases/verify_scanned_item_usecase.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/pick_verify_controller.dart';

class PickVerifyScreen extends ConsumerStatefulWidget {
  const PickVerifyScreen({required this.orderId, this.item, super.key});

  final String orderId;
  final PickListItem? item;

  @override
  ConsumerState<PickVerifyScreen> createState() => _PickVerifyScreenState();
}

class _PickVerifyScreenState extends ConsumerState<PickVerifyScreen> {
  late final MobileScannerController _scannerController;
  bool _isProcessingScan = false;
  int _pickedQuantity = 0;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _pickedQuantity = widget.item?.pickedQuantity ?? 0;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final item = widget.item;
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (item == null || value.isEmpty || _isProcessingScan) return;

    _isProcessingScan = true;
    await _scannerController.stop();

    ref.read(pickVerifyControllerProvider.notifier).verifyScan(
          scannedBarcode: value,
          expectedBarcode: item.barcode,
          currentPicked: _pickedQuantity,
          expectedQuantity: item.expectedQuantity,
        );

    final result = ref.read(pickVerifyControllerProvider).lastResult;
    if (!mounted) return;

    if (result == VerifyResult.match) {
      setState(() => _pickedQuantity++);
      await _showMessage('Đã xác nhận sản phẩm: $value');
    } else if (result == VerifyResult.mismatch) {
      await _showMessage('Mã vạch không khớp sản phẩm cần lấy.');
    } else if (result == VerifyResult.overQuantity) {
      await _showMessage('Số lượng đã vượt quá số lượng cần lấy.');
    }

    if (mounted) {
      _isProcessingScan = false;
      await _scannerController.start();
    }
  }

  Future<void> _showMessage(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận lấy hàng'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        title: Text('Xác nhận phiếu ${widget.orderId}'),
        actions: [
          IconButton(
            tooltip: 'Đèn flash',
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: item == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Chưa có sản phẩm cần lấy để xác nhận.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                ListTile(
                  title: Text(item.productName),
                  subtitle: Text(
                    '${item.locationLabel} • $_pickedQuantity/${item.expectedQuantity}',
                  ),
                  leading: const Icon(Icons.inventory_2_outlined),
                ),
                Expanded(
                  child: MobileScanner(
                    controller: _scannerController,
                    onDetect: _handleBarcode,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Đưa mã vạch sản phẩm vào khung quét.'),
                ),
              ],
            ),
    );
  }

}

