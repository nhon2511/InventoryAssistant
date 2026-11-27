import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/camera_scan_dialog.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/location_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/orders/domain/usecases/apply_order_scan.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_labels.dart';
import 'package:uuid/uuid.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({
    required this.type,
    required this.orderId,
    super.key,
  });
  final OrderType type;
  final String orderId;
  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool busy = false;
  String? error;
  String? confirmationKey;
  final actualControllers = <String, TextEditingController>{};
  final barcodeController = TextEditingController();
  final previewControllers = <String, TextEditingController>{};
  String? scanMessage;
  String? previousCameraBarcode;
  DateTime? previousCameraAt;
  final scanHistory = <(String, String)>[];

  @override
  void dispose() {
    for (final controller in actualControllers.values) {
      controller.dispose();
    }
    for (final controller in previewControllers.values) {
      controller.dispose();
    }
    barcodeController.dispose();
    super.dispose();
  }

  void applyScan(
    WarehouseOrder order,
    List<Product> products,
    String barcode, {
    bool fromCamera = false,
  }) {
    final now = DateTime.now();
    final quantities = {
      for (final line in order.items)
        line.id:
            int.tryParse(actualControllers[line.id]?.text.trim() ?? '') ?? 0,
    };
    final result = const ApplyOrderScan()(
      order: order,
      products: products,
      actualQuantities: quantities,
      barcode: barcode,
      now: now,
      previousCameraBarcode: previousCameraBarcode,
      previousCameraAt: previousCameraAt,
      fromCamera: fromCamera,
    );
    setState(() {
      scanMessage = result.message;
      if (result.accepted) {
        scanHistory.add((
          result.lineId!,
          actualControllers[result.lineId]!.text,
        ));
        actualControllers[result.lineId]!.text = result.quantity.toString();
        confirmationKey = null;
        barcodeController.clear();
        if (fromCamera) {
          previousCameraBarcode = barcode.trim();
          previousCameraAt = now;
        }
        scanMessage = 'Đã cộng 1 vào đúng dòng phiếu.';
      }
    });
  }

  Future<void> resetScans() async {
    if (scanHistory.isEmpty) return;
    if (!await ConfirmDialog.show(
      context,
      title: 'Xóa phiên quét?',
      content: 'Hoàn tác các lần quét của phiên này; số lượng nhập tay trước đó được giữ lại.',
      isDestructive: true,
    )) {
      return;
    }
    if (!mounted) return;
    setState(() {
      for (final entry in scanHistory.reversed) {
        actualControllers[entry.$1]?.text = entry.$2;
      }
      scanHistory.clear();
      confirmationKey = null;
      scanMessage = 'Đã xóa phiên quét.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final key = (widget.type, widget.orderId);
    final auth = ref.watch(authControllerProvider);
    final profile = auth is AuthAuthenticated ? auth.profile : null;
    final products = ref.watch(productControllerProvider).value ?? [];
    final locations = ref.watch(locationControllerProvider).value ?? [];
    final manager = profile?.role.isManagerOrAbove ?? false;
    return Scaffold(
      body: AsyncPanel(
        value: ref.watch(orderDetailProvider(key)),
        onRetry: () => ref.invalidate(orderDetailProvider(key)),
        builder: (order) => WorkspaceContent(
          child: ListView(
            padding: workspacePadding(context),
            children: [
              WorkspaceHeader(
                title: order.orderCode,
                description:
                    'Chi tiết phiếu ${widget.type == OrderType.inbound ? "nhập" : "xuất"}',
                actions: [
                  TextButton.icon(
                    onPressed: () => context.go(
                      widget.type == OrderType.inbound
                          ? '/inbound'
                          : '/outbound',
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Danh sách phiếu'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Trạng thái: ${orderStatusLabel(order.status)}\nNgười tạo: ${order.createdBy ?? "Chưa cung cấp"}\nNgười duyệt: ${order.approvedBy ?? "Chưa có"}\nNgày tạo: ${order.createdAt == null ? "Chưa cung cấp" : DateFormat("dd/MM/yyyy HH:mm").format(order.createdAt!)}',
              ),
              if (order.note?.isNotEmpty ?? false)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Ghi chú: ${order.note}'),
                ),
              const Divider(height: 32),
              Text('Dòng hàng', style: Theme.of(context).textTheme.titleLarge),
              if (order.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Chưa nhận được dòng hàng. Phiếu xuất hiện chưa có contract tải đầy đủ line items; không thể đối soát khi thiếu dữ liệu.',
                  ),
                ),
              for (final item in order.items)
                ListTile(
                  title: Text(
                    item.productName ??
                        products
                            .where((p) => p.id == item.productId)
                            .firstOrNull
                            ?.name ??
                        item.productId,
                  ),
                  subtitle: Text(
                    [
                      'Vị trí: ${locations.where((l) => l.id == item.locationId).firstOrNull?.displayLabel ?? item.locationId ?? "Chưa chọn"}',
                      'Dự kiến: ${item.expectedQuantity} · Thực tế: ${item.actualQuantity}',
                      if (widget.type == OrderType.inbound &&
                          item.lotNumber != null)
                        'Số lô: ${item.lotNumber}',
                      if (widget.type == OrderType.inbound &&
                          item.expiryDate != null)
                        'Hạn sử dụng: ${DateFormat("dd/MM/yyyy").format(item.expiryDate!)}',
                    ].join('\n'),
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Duyệt phiếu chưa cập nhật tồn kho. Xác nhận sau khi nhập số lượng thực tế.',
              ),
              if (manager &&
                  !ref.watch(orderWorkflowRepositoryProvider).available)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Duyệt / từ chối: chưa khả dụng, chờ adapter backend.',
                  ),
                ),
              if (manager && order.status == OrderStatus.draft)
                Wrap(
                  spacing: 12,
                  children: [
                    for (final approve in [true, false])
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () async {
                                if (!await ConfirmDialog.show(
                                  context,
                                  title: approve
                                      ? 'Duyệt phiếu?'
                                      : 'Từ chối phiếu?',
                                  content: approve
                                      ? 'Chuyển Nháp → Đã duyệt. Không cập nhật tồn kho.'
                                      : 'Chuyển Nháp → Đã hủy / từ chối.',
                                  isDestructive: !approve,
                                )) {
                                  return;
                                }
                                if (!mounted) return;
                                setState(() {
                                  busy = true;
                                  error = null;
                                });
                                final result = await ref
                                    .read(orderWorkspaceProvider)
                                    .review(order, profile!, approve: approve);
                                if (!mounted) return;
                                result.fold(
                                  (f) => setState(() {
                                    busy = false;
                                    error = f.message;
                                  }),
                                  (_) {
                                    setState(() => busy = false);
                                    ref
                                      ..invalidate(orderDetailProvider(key))
                                      ..invalidate(ordersProvider(widget.type));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Đã cập nhật trạng thái phiếu; tồn kho chưa thay đổi.',
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                        child: Text(approve ? 'Duyệt' : 'Từ chối'),
                      ),
                  ],
                ),
              if (manager &&
                  profile?.id == order.createdBy &&
                  order.status == OrderStatus.confirmed &&
                  order.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Số lượng thực tế',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Nhập từ 1 đến số lượng dự kiến cho từng dòng. Tồn kho chỉ đổi sau khi xác nhận thành công.',
                ),
                for (final line in order.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: TextField(
                      controller: actualControllers.putIfAbsent(
                        line.id,
                        TextEditingController.new,
                      ),
                      enabled: !busy,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            '${line.productName ?? line.productId} · dự kiến ${line.expectedQuantity}',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        confirmationKey = null;
                        scanHistory.clear();
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Quét mã vào phiếu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Quét hoặc nhập mã chỉ cộng số lượng trong form. Xác nhận tồn kho vẫn là bước riêng.',
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: barcodeController,
                        enabled: !busy,
                        decoration: const InputDecoration(
                          labelText: 'Mã vạch',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (value) =>
                            applyScan(order, products, value),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đối soát mã',
                      onPressed: busy
                          ? null
                          : () => applyScan(
                              order,
                              products,
                              barcodeController.text,
                            ),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    IconButton(
                      tooltip: 'Mở camera',
                      onPressed: busy || !CameraScanDialog.supported
                          ? null
                          : () async {
                              final code = await showDialog<String>(
                                context: context,
                                builder: (_) => const CameraScanDialog(),
                              );
                              if (mounted && code != null) {
                                applyScan(
                                  order,
                                  products,
                                  code,
                                  fromCamera: true,
                                );
                              }
                            },
                      icon: const Icon(Icons.qr_code_scanner),
                    ),
                  ],
                ),
                if (scanMessage != null) Text(scanMessage!),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: busy || scanHistory.isEmpty
                          ? null
                          : () {
                              final previous = scanHistory.removeLast();
                              setState(() {
                                actualControllers[previous.$1]!.text =
                                    previous.$2;
                                confirmationKey = null;
                                scanMessage = 'Đã hoàn tác lần quét cuối.';
                              });
                            },
                      icon: const Icon(Icons.undo),
                      label: const Text('Hoàn tác quét'),
                    ),
                    TextButton.icon(
                      onPressed: busy || scanHistory.isEmpty
                          ? null
                          : resetScans,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa phiên quét'),
                    ),
                  ],
                ),
                if (widget.type == OrderType.inbound) ...[
                  const Text(
                    'LOT/HSD: chỉ xem trước trên phiếu đã duyệt; API confirm hiện chưa lưu thay đổi này.',
                  ),
                  for (final line in order.items) ...[
                    Text(line.productName ?? line.productId),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: previewControllers.putIfAbsent(
                              '${line.id}:lot',
                              () => TextEditingController(
                                text: line.lotNumber ?? '',
                              ),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'LOT xem trước / nhập tay',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: previewControllers.putIfAbsent(
                              '${line.id}:expiry',
                              () => TextEditingController(
                                text: line.expiryDate == null
                                    ? ''
                                    : DateFormat('dd/MM/yyyy')
                                          .format(line.expiryDate!),
                              ),
                            ),
                            decoration: const InputDecoration(
                              labelText: 'HSD xem trước / nhập tay',
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Đọc nhãn bằng OCR',
                          onPressed: busy
                              ? null
                              : () async {
                                  final values = await context
                                      .push<Map<String, String>>(
                                        '/ocr-scan',
                                        extra: 'inbound-line',
                                      );
                                  if (!mounted || values == null) return;
                                  setState(() {
                                    if (values['lotNumber'] != null) {
                                      previewControllers['${line.id}:lot']!
                                              .text =
                                          values['lotNumber']!;
                                    }
                                    if (values['expiryDate'] != null) {
                                      previewControllers['${line.id}:expiry']!
                                              .text =
                                          values['expiryDate']!;
                                    }
                                  });
                                },
                          icon: const Icon(Icons.document_scanner_outlined),
                        ),
                      ],
                    ),
                  ],
                ],
                FilledButton.icon(
                  onPressed: busy
                      ? null
                      : () async {
                          final quantities = {
                            for (final line in order.items)
                              line.id:
                                  int.tryParse(
                                    actualControllers[line.id]!.text.trim(),
                                  ) ??
                                  0,
                          };
                          if (!await ConfirmDialog.show(
                            context,
                            title: 'Xác nhận nhập/xuất kho?',
                            content: 'Cập nhật tồn kho theo số lượng thực tế đã nhập và hoàn tất phiếu.',
                          )) {
                            return;
                          }
                          if (!mounted) {
                            return;
                          }
                          confirmationKey ??= const Uuid().v4();
                          setState(() {
                            busy = true;
                            error = null;
                          });
                          final result = await ref
                              .read(orderWorkspaceProvider)
                              .confirm(
                                order,
                                profile!,
                                actualQuantities: quantities,
                                idempotencyKey: confirmationKey!,
                              );
                          if (!mounted) return;
                          result.fold(
                            (failure) => setState(() {
                              busy = false;
                              error = failure.message;
                            }),
                            (_) {
                              setState(() => busy = false);
                              ref
                                ..invalidate(orderDetailProvider(key))
                                ..invalidate(ordersProvider(widget.type))
                                ..invalidate(stockSnapshotProvider)
                                ..invalidate(stockOverviewItemsProvider);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Đã hoàn tất phiếu và cập nhật tồn kho.',
                                  ),
                                ),
                              );
                            },
                          );
                        },
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(busy ? 'Đang xác nhận...' : 'Xác nhận tồn kho'),
                ),
              ],
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
