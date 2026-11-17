import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/features/outbound/domain/entities/pick_list_item.dart';
import 'package:smart_wms/features/outbound/domain/usecases/verify_scanned_item_usecase.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/pick_verify_controller.dart';

class PickVerifyScreen extends ConsumerStatefulWidget {
  const PickVerifyScreen({
    required this.orderId,
    this.items = const [],
    super.key,
  });

  final String orderId;
  final List<PickListItem> items;

  @override
  ConsumerState<PickVerifyScreen> createState() => _PickVerifyScreenState();
}

class _PickVerifyScreenState extends ConsumerState<PickVerifyScreen> {
  late final MobileScannerController _scannerController;
  late final TextEditingController _barcodeController;
  PickListItem? _selectedItem;
  bool _isProcessingScan = false;
  final Map<PickListItem, int> _pickedQuantities = {};
  int _pickedQuantity = 0;

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController();
    _barcodeController = TextEditingController();
    _selectedItem = widget.items.isEmpty ? null : widget.items.first;
    _pickedQuantity = _selectedItem?.pickedQuantity ?? 0;
    for (final item in widget.items) {
      _pickedQuantities[item] = item.pickedQuantity;
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _barcodeController.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    final value = capture.barcodes
        .map((barcode) => barcode.rawValue)
        .whereType<String>()
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');

    if (value.isEmpty) return;
    await _verifyBarcode(value, pauseScanner: true);
  }

  Future<void> _verifyBarcode(String value, {bool pauseScanner = false}) async {
    final item = _selectedItem;
    if (item == null || value.trim().isEmpty || _isProcessingScan) return;

    _isProcessingScan = true;
    if (pauseScanner) await _scannerController.stop();

    ref
        .read(pickVerifyControllerProvider.notifier)
        .verifyScan(
          scannedBarcode: value.trim(),
          expectedBarcode: item.barcode,
          currentPicked: _pickedQuantity,
          expectedQuantity: item.expectedQuantity,
        );

    final result = ref.read(pickVerifyControllerProvider).lastResult;
    if (!mounted) return;

    if (result == VerifyResult.match) {
      setState(() {
        _pickedQuantity++;
        _pickedQuantities[item] = _pickedQuantity;
        _barcodeController.clear();
      });
      await _showMessage('Đã xác nhận sản phẩm: ${item.productName}');
    } else if (result == VerifyResult.mismatch) {
      await _showMessage('Mã vạch không khớp sản phẩm cần lấy.');
    } else if (result == VerifyResult.overQuantity) {
      await _showMessage('Số lượng đã vượt quá số lượng cần lấy.');
    }

    if (mounted) {
      _isProcessingScan = false;
      if (pauseScanner) await _scannerController.start();
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
    final item = _selectedItem;
    final canVerify = item != null && item.barcode.trim().isNotEmpty;
    final remainingQuantity = item == null
        ? 0
        : item.expectedQuantity - _pickedQuantity;
    final isComplete = item != null && remainingQuantity <= 0;
    final progress = item == null || item.expectedQuantity <= 0
        ? 0.0
        : (_pickedQuantity / item.expectedQuantity).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        leading: ScannerBackButton(fallback: '/outbound/${widget.orderId}'),
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
                if (widget.items.length > 1)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: DropdownButtonFormField<PickListItem>(
                      initialValue: item,
                      decoration: const InputDecoration(
                        labelText: 'Mặt hàng cần lấy',
                        border: OutlineInputBorder(),
                      ),
                      items: widget.items.map((pickItem) {
                        final picked =
                            _pickedQuantities[pickItem] ??
                            pickItem.pickedQuantity;
                        final remaining = (pickItem.expectedQuantity - picked)
                            .clamp(0, pickItem.expectedQuantity);
                        return DropdownMenuItem(
                          value: pickItem,
                          child: Text(
                            '${pickItem.productName} ($remaining còn lại)${pickItem.barcode.trim().isEmpty ? ' • thiếu mã vạch' : ''}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (nextItem) {
                        if (nextItem == null) return;
                        setState(() {
                          _selectedItem = nextItem;
                          _pickedQuantity =
                              _pickedQuantities[nextItem] ??
                              nextItem.pickedQuantity;
                          _barcodeController.clear();
                        });
                      },
                    ),
                  ),
                ListTile(
                  title: Text(item.productName),
                  subtitle: Text(
                    '${item.locationLabel} • $_pickedQuantity/${item.expectedQuantity}',
                  ),
                  leading: const Icon(Icons.inventory_2_outlined),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tiến độ lấy hàng'),
                          Chip(
                            label: Text(
                              isComplete
                                  ? 'Đã lấy đủ'
                                  : 'Còn $remainingQuantity',
                            ),
                            avatar: Icon(
                              isComplete
                                  ? Icons.check_circle_outline
                                  : Icons.pending_outlined,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      Semantics(
                        label:
                            'Đã lấy $_pickedQuantity trên ${item.expectedQuantity}',
                        child: LinearProgressIndicator(value: progress),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Kết quả chỉ theo dõi trong phiên này; chưa lưu phiếu hoặc cập nhật tồn kho.',
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: canVerify
                      ? MobileScanner(
                          controller: _scannerController,
                          onDetect: _handleBarcode,
                          errorBuilder: (context, error, child) => Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'Không mở được camera. Bạn có thể nhập mã vạch bên dưới để tiếp tục.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Dòng hàng này chưa có mã vạch trong dữ liệu nên chưa thể đối soát. Hãy chọn dòng khác hoặc bổ sung mã vạch trong sản phẩm.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Quét camera hoặc nhập mã vạch thủ công.'),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _barcodeController,
                          enabled: !_isProcessingScan && canVerify,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _verifyBarcode,
                          decoration: const InputDecoration(
                            labelText: 'Nhập mã vạch thủ công',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _isProcessingScan || !canVerify
                            ? null
                            : () => _verifyBarcode(_barcodeController.text),
                        child: const Text('Xác nhận'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
