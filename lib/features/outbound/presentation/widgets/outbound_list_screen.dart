import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/outbound/presentation/controllers/outbound_controller.dart';

/// Screen displaying the list of outbound orders.
class OutboundListScreen extends ConsumerWidget {
  const OutboundListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(outboundControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu xuất kho')),
      body: ordersAsync.when(
        loading: () => const AppLoadingWidget(message: 'Đang tải phiếu xuất...'),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(outboundControllerProvider),
        ),
        data: (orders) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.output_rounded),
                title: Text(order.orderCode),
                subtitle: Text('Trạng thái: ${order.status.dbValue}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Create new outbound order
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu xuất'),
      ),
    );
  }
}
