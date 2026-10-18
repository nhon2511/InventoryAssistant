import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/location_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_labels.dart';

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
  @override
  Widget build(BuildContext context) {
    final key = (widget.type, widget.orderId);
    final auth = ref.watch(authControllerProvider);
    final products = ref.watch(productControllerProvider).value ?? [];
    final locations = ref.watch(locationControllerProvider).value ?? [];
    final manager =
        auth is AuthAuthenticated && auth.profile.role.isManagerOrAbove;
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
                    'Vị trí: ${locations.where((l) => l.id == item.locationId).firstOrNull?.displayLabel ?? item.locationId ?? "Chưa chọn"}\nDự kiến: ${item.expectedQuantity} · Thực tế: ${item.actualQuantity}',
                  ),
                ),
              const SizedBox(height: 16),
              const Text(
                'Duyệt phiếu không xác nhận đã cập nhật tồn kho. Xử lý nhập/xuất an toàn cần contract backend riêng.',
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
                                    .review(
                                      order,
                                      auth.profile,
                                      approve: approve,
                                    );
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
              if (widget.type == OrderType.outbound &&
                  order.items.isNotEmpty &&
                  !order.status.isTerminal)
                OutlinedButton.icon(
                  onPressed: () => context.push('/pick-verify/${order.id}'),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Đối soát mã hàng'),
                ),
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
