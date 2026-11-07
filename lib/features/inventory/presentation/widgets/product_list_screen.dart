import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/inventory_edit_dialog.dart';

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});
  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  String query = '';
  String? unit;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.profile.role.isAdmin;
    return Scaffold(
      body: AsyncPanel(
        value: ref.watch(productControllerProvider),
        onRetry: () => ref.invalidate(productControllerProvider),
        builder: (products) {
          final units = products.map((p) => p.unit).toSet().toList()..sort();
          final filtered = products
              .where(
                (p) =>
                    (unit == null || unit == p.unit) &&
                    '${p.name} ${p.sku} ${p.barcode}'.toLowerCase().contains(
                      query.toLowerCase(),
                    ),
              )
              .toList();
          return WorkspaceContent(
            child: Column(
              children: [
                Padding(
                  padding: workspacePadding(context).copyWith(bottom: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      WorkspaceHeader(
                        title: 'Sản phẩm',
                        description: 'Tra cứu SKU, mã vạch và đơn vị hàng hóa.',
                        actions: [
                          if (admin)
                            FilledButton.icon(
                              onPressed: () => showDialog<void>(
                                context: context,
                                builder: (_) => const InventoryEditDialog(),
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Thêm'),
                            ),
                        ],
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: 'Tìm tên, SKU hoặc mã vạch',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (v) => setState(() => query = v),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 52,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(
                      horizontal: workspacePadding(context).left,
                    ),
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả đơn vị'),
                        selected: unit == null,
                        onSelected: (_) => setState(() => unit = null),
                      ),
                      for (final value in units)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(value),
                            selected: unit == value,
                            onSelected: (_) => setState(() => unit = value),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: workspacePadding(context)
                      .copyWith(top: 0, bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('${filtered.length} sản phẩm'),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'Không có sản phẩm phù hợp. Hãy đổi từ khóa hoặc bộ lọc.',
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: workspacePadding(context).left,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final product = filtered[index];
                            return ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(product.name),
                              subtitle: Text(
                                '${product.sku} · ${product.unit}\nMã vạch: ${product.barcode}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.go('/products/${product.id}'),
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
