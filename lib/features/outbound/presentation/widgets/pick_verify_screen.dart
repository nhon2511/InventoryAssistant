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

class _PickVerifyScreenState extends ConsumerState<PickVerifyScreen> {
  final input = TextEditingController();
  final counts = <String, int>{};
  String? selected;
  String? message;
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

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: ScannerBackButton(fallback: '/outbound/${widget.orderId}'),
      title: const Text('Đối soát xuất kho'),
    ),
    body: AsyncPanel(
      value: ref.watch(
        orderDetailProvider((OrderType.outbound, widget.orderId)),
      ),
      onRetry: () => ref.invalidate(
        orderDetailProvider((OrderType.outbound, widget.orderId)),
      ),
      builder: (order) => AsyncPanel(
        value: ref.watch(productControllerProvider),
        onRetry: () => ref.invalidate(productControllerProvider),
        builder: (products) {
          if (order.items.isEmpty || order.status.isTerminal) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Không thể đối soát: phiếu đã kết thúc hoặc chưa nhận được dòng hàng.',
                ),
              ),
            );
          }
          final item =
              order.items.where((i) => i.id == selected).firstOrNull ??
              order.items.first;
          final product = products
              .where((p) => p.id == item.productId)
              .firstOrNull;
          void verify() {
            if (product == null || input.text.trim().isEmpty) {
              setState(() => message = 'Chưa có sản phẩm hoặc chưa nhập mã.');
              return;
            }
            ref
                .read(pickVerifyControllerProvider.notifier)
                .verifyScan(
                  scannedBarcode: input.text.trim(),
                  expectedBarcode: product.barcode,
                  currentPicked: counts[item.id] ?? 0,
                  expectedQuantity: item.expectedQuantity,
                );
            final result = ref.read(pickVerifyControllerProvider).lastResult;
            setState(() {
              message = switch (result) {
                VerifyResult.match => 'Mã khớp · Đã ghi nhận đối soát trong phiên (chưa lưu backend).',
                VerifyResult.mismatch => 'Sai mã hàng. Không tăng số lượng.',
                VerifyResult.overQuantity =>
                  'Đã đủ số lượng dự kiến. Không tăng thêm.',
                null => 'Chưa có kết quả.',
              };
              if (result == VerifyResult.match) {
                counts[item.id] = (counts[item.id] ?? 0) + 1;
              }
            });
            input.clear();
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: ListView(
                padding: workspacePadding(context),
                children: [
                  Text(
                    order.orderCode,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Text(
                    'Đối soát mã theo từng dòng · Số đếm chỉ trong phiên. Chưa xác nhận xuất hoặc cập nhật tồn.',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: item.id,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Dòng hàng đang đối soát',
                    ),
                    items: order.items
                        .map(
                          (i) => DropdownMenuItem(
                            value: i.id,
                            child: Text(
                              i.productName ?? i.productId,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => selected = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: input,
                    decoration: const InputDecoration(labelText: 'Mã vạch'),
                    onSubmitted: (_) => verify(),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    children: [
                      FilledButton(
                        onPressed: verify,
                        child: const Text('Đối soát mã'),
                      ),
                      OutlinedButton(
                        onPressed: CameraScanDialog.supported
                            ? () async {
                                final code = await showDialog<String>(
                                  context: context,
                                  builder: (_) => const CameraScanDialog(),
                                );
                                if (code != null && mounted) {
                                  input.text = code;
                                  verify();
                                }
                              }
                            : null,
                        child: const Text('Camera'),
                      ),
                      TextButton(
                        onPressed: () async {
                          if (await ConfirmDialog.show(
                            context,
                            title: 'Xóa số đếm phiên?',
                            content: 'Các số đếm đối soát sẽ về 0.',
                          )) {
                            if (mounted) {
                              setState(() {
                                counts.clear();
                                message = null;
                              });
                            }
                          }
                        },
                        child: const Text('Đếm lại'),
                      ),
                    ],
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(message!),
                    ),
                  for (final i in order.items)
                    ListTile(
                      title: Text(i.productName ?? i.productId),
                      subtitle: Text(
                        'Đã đối soát: ${counts[i.id] ?? 0} / ${i.expectedQuantity}',
                      ),
                    ),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Lưu kết quả và hoàn tất xuất: chưa khả dụng'),
                    subtitle: Text(
                      'Cần backend kiểm tra quyền, trạng thái, tồn và giao dịch nguyên tử.',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ),
  );
}

