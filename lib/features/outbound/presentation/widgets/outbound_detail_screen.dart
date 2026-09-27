import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/outbound_controller.dart';

/// Screen displaying details of a single outbound order.
class OutboundDetailScreen extends ConsumerWidget {
  const OutboundDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(outboundControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu xuất')),
      body: orders.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('$error')),
        data: (_) => FutureBuilder<WarehouseOrder>(
          future: ref.read(outboundControllerProvider.notifier).getById(orderId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return snapshot.hasError
                  ? Center(child: Text('${snapshot.error}'))
                  : const AppLoadingWidget();
            }
            final order = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(order.orderCode, style: Theme.of(context).textTheme.headlineSmall),
                Text('Trạng thái: ${order.status.dbValue}'),
                if (order.note != null) Text('Ghi chú: ${order.note}'),
                const SizedBox(height: 16),
                Text('Sản phẩm trong phiếu', style: Theme.of(context).textTheme.titleMedium),
                if (order.items.isEmpty)
                  const ListTile(title: Text('Chưa có sản phẩm trong phiếu.')),
                for (final item in order.items)
                  ListTile(
                    title: Text(item.productName ?? item.productId),
                    trailing: Text('${item.expectedQuantity}'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
