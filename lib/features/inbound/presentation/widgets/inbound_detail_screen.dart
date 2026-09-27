import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/presentation/controllers/inbound_controller.dart';

/// Screen displaying details of a single inbound order.
class InboundDetailScreen extends ConsumerWidget {
  const InboundDetailScreen({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(inboundControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết phiếu nhập')),
      body: orders.when(
        loading: () => const AppLoadingWidget(),
        error: (error, _) => Center(child: Text('$error')),
        data: (_) => FutureBuilder<WarehouseOrder>(
          future: ref.read(inboundControllerProvider.notifier).getById(orderId),
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
                    subtitle: Text(item.lotNumber ?? 'Chưa có mã lô'),
                    trailing: Text('${item.actualQuantity}'),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
