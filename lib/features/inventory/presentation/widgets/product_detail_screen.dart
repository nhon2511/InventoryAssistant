import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/inventory_edit_dialog.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({required this.productId, super.key});
  final String productId;
  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.profile.role.isAdmin;
    return Scaffold(
      body: AsyncPanel(
        value: ref.watch(productDetailProvider(widget.productId)),
        onRetry: () => ref.invalidate(productDetailProvider(widget.productId)),
        builder: (p) => WorkspaceContent(
          child: ListView(
            padding: workspacePadding(context),
            children: [
              WorkspaceHeader(
                title: p.name,
                description: 'SKU ${p.sku} · ${p.unit}',
                actions: [
                  TextButton.icon(
                    onPressed: () => context.go('/products'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Sản phẩm'),
                  ),
                ],
              ),
              if (admin &&
                  !ref.watch(inventoryMaintenanceRepositoryProvider).available)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'Thêm / sửa / xóa: chưa khả dụng, chờ adapter backend.',
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'SKU: ${p.sku}\nMã vạch: ${p.barcode}\nĐơn vị: ${p.unit}\nTồn an toàn: ${p.minSafetyStock} ${p.unit}',
              ),
              if (p.description != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(p.description!),
                ),
              if (admin)
                Wrap(
                  spacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => InventoryEditDialog(product: p),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Sửa'),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy
                          ? null
                          : () async {
                              if (!await ConfirmDialog.show(
                                context,
                                title: 'Xóa sản phẩm?',
                                content:
                                    'Xóa ${p.name}? Backend phải kiểm tra tồn kho và tham chiếu trước khi xóa.',
                                isDestructive: true,
                              )) {
                                return;
                              }
                              if (!mounted) return;
                              setState(() => busy = true);
                              final result = await ref
                                  .read(maintainInventoryProvider)
                                  .deleteProduct(p.id, auth.profile.role);
                              if (!mounted) return;
                              setState(() => busy = false);
                              result.fold(
                                (f) => ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                      SnackBar(content: Text(f.message)),
                                    ),
                                (_) {
                                  ref.invalidate(productControllerProvider);
                                  context.go('/products');
                                },
                              );
                            },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Xóa'),
                    ),
                  ],
                ),
              const Divider(height: 32),
              Text(
                'Tồn kho theo vị trí',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              AsyncPanel(
                value: ref.watch(productStockProvider(p.id)),
                onRetry: () => ref.invalidate(productStockProvider(p.id)),
                builder: (items) => Column(
                  children: [
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Chưa có tồn kho cho sản phẩm này.'),
                      ),
                    for (final item in items)
                      ListTile(
                        title: Text(item.locationLabel ?? item.locationId),
                        subtitle: Text(
                          'Thực có: ${item.quantityOnHand} · Giữ chỗ: ${item.quantityReserved}\nLô: ${item.lotNumber ?? "—"}',
                        ),
                        trailing: Text(
                          '${item.quantityAvailable}\nkhả dụng',
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
