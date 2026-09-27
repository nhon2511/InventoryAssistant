import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/core/widgets/empty_state_widget.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/product_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_realtime_controller.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';

/// Screen displaying the list of all products.
class ProductListScreen extends HookConsumerWidget {
  const ProductListScreen({super.key, this.stockFilter});
  final String? stockFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productControllerProvider);
    final search = useState('');
    final stockAsync = stockFilter == null ? null : ref.watch(inventoryRealtimeProvider);
    final stockItems = stockAsync == null ? const <InventoryItem>[] : stockAsync.when(
      data: (items) => items,
      loading: () => const <InventoryItem>[],
      error: (_, _) => const <InventoryItem>[],
    );
    final stockByProduct = <String, int>{};
    for (final item in stockItems) {
      stockByProduct.update(item.productId, (old) => old + item.quantityAvailable,
        ifAbsent: () => item.quantityAvailable);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Sản phẩm')),
      body: productsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Đang tải sản phẩm...'),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(productControllerProvider),
        ),
        data: (products) {
          final filtered = products.where((product) {
            final query = search.value.trim().toLowerCase();
            final matchesText = product.name.toLowerCase().contains(query) ||
                product.sku.toLowerCase().contains(query) ||
                product.barcode.contains(query);
            if (!matchesText || stockFilter == null) return matchesText;
            final quantity = stockByProduct[product.id] ?? 0;
            if (stockFilter == 'out') return quantity <= 0;
            if (stockFilter == 'low') return quantity > 0 && quantity <= product.minSafetyStock;
            return true;
          }).toList();
          return Column(children: [
            if (stockFilter == 'low' || stockFilter == 'out')
              ListTile(title: Text(stockFilter == 'low' ? 'Sản phẩm sắp hết' : 'Sản phẩm hết hàng'),
                trailing: TextButton(onPressed: () => context.go('/products'), child: const Text('Bỏ lọc'))),
            Padding(
              padding: const EdgeInsets.all(AppTokens.lg),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Tìm tên, SKU hoặc mã vạch',
                ),
                onChanged: (value) => search.value = value,
              ),
            ),
            Expanded(
              child: stockAsync?.isLoading == true
                  ? const AppLoadingWidget(message: 'Đang tải tồn kho...')
                  : stockAsync?.hasError == true
                      ? AppErrorWidget(message: stockAsync!.error.toString(),
                          onRetry: () => ref.invalidate(inventoryRealtimeProvider))
                  : filtered.isEmpty
                  ? EmptyStateWidget(
                      message: products.isEmpty
                          ? 'Chưa có sản phẩm.'
                          : 'Không tìm thấy sản phẩm phù hợp.',
                    )
                  : ListView.builder(
          padding: const EdgeInsets.all(AppTokens.sm),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final product = filtered[index];
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(product.name.isEmpty ? '?' : product.name[0].toUpperCase()),
                ),
                title: Text(product.name),
                subtitle: Text('SKU: ${product.sku} • ${product.unit}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/products/${product.id}'),
              ),
            );
          },
        )),
          ]);
        },
      ),
    );
  }
}
