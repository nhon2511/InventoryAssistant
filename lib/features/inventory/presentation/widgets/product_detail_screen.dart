import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/app/theme/app_tokens.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/core/widgets/status_chip.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_repository_provider.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Screen displaying details of a single product.
class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repository = ref.watch(inventoryRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết sản phẩm')),
      body: FutureBuilder(
        future: _loadDetails(repository),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            if (snapshot.hasError) {
              return Center(child: Text('Không tải được sản phẩm: ${snapshot.error}'));
            }
            return const AppLoadingWidget();
          }
          final productResult = snapshot.data!.product;
          final stockResult = snapshot.data!.stock;
          return productResult.fold(
            (failure) => Center(child: Text(failure.message)),
            (product) => stockResult.fold(
              (failure) => Center(child: Text(failure.message)),
              (stock) => _ProductDetails(product: product, stock: stock),
            ),
          );
        },
      ),
    );
  }

  Future<({
    Either<Failure, Product> product,
    Either<Failure, List<InventoryItem>> stock,
  })> _loadDetails(InventoryRepository repository) async => (
        product: await repository.getProductById(productId),
        stock: await repository.getStockByProduct(productId),
      );
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product, required this.stock});
  final Product product;
  final List<InventoryItem> stock;

  @override
  Widget build(BuildContext context) {
    final available = stock.fold<int>(
      0, (sum, item) => sum + item.quantityAvailable,
    );
    return ListView(
      padding: const EdgeInsets.all(AppTokens.lg),
      children: [
        Text(product.name, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: AppTokens.sm),
        Text('SKU: ${product.sku} · Mã vạch: ${product.barcode}'),
        Text('Đơn vị: ${product.unit} · Tồn tối thiểu: ${product.minSafetyStock}'),
        const SizedBox(height: AppTokens.lg),
        available <= 0
            ? const StatusChip.outOfStock()
            : available <= product.minSafetyStock
                ? const StatusChip.lowStock()
                : const StatusChip.inStock(),
        Text('Có thể xuất: $available', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppTokens.lg),
        Text('Lô và vị trí', style: Theme.of(context).textTheme.titleMedium),
        for (final item in stock)
          Card(
            child: ListTile(
              title: Text(item.lotNumber ?? 'Chưa có mã lô'),
              subtitle: Text(item.locationLabel ?? item.locationId),
              trailing: Text('${item.quantityAvailable} ${product.unit}'),
            ),
          ),
      ],
    );
  }
}
