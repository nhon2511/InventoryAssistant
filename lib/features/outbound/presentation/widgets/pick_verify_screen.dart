import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/camera_scan_dialog.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:smart_wms/features/outbound/domain/usecases/verify_scanned_item_usecase.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/pick_verify_controller.dart';

class PickVerifyScreen extends ConsumerStatefulWidget {
  const PickVerifyScreen({required this.orderId, super.key});
  final String orderId;
  @override
  ConsumerState<PickVerifyScreen> createState() => _PickVerifyScreenState();
}

class _PickVerifyScreenState extends ConsumerState<PickVerifyScreen> {
  final input = TextEditingController();
  final counts = <String, int>{};
  String? selected;
  String? message;
  @override
  void dispose() {
    input.dispose();
    super.dispose();
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
