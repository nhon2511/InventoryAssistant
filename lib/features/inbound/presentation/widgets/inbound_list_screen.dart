import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/widgets/empty_state_widget.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/inbound/presentation/controllers/inbound_controller.dart';

/// Screen displaying the list of inbound orders.
class InboundListScreen extends ConsumerWidget {
  const InboundListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(inboundControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Phiếu nhập kho')),
      body: ordersAsync.when(
        loading: () => const AppLoadingWidget(message: 'Đang tải phiếu nhập...'),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(inboundControllerProvider),
        ),
        data: (orders) => orders.isEmpty
            ? const EmptyStateWidget(message: 'Chưa có phiếu nhập kho.')
            : ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.input_rounded),
                title: Text(order.orderCode),
                subtitle: Text('Trạng thái: ${order.status.dbValue}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/inbound/${order.id}'),
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final id = await ref.read(inboundControllerProvider.notifier).createDraft();
            if (context.mounted) context.go('/inbound/$id');
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Không tạo được phiếu: $error')),
              );
            }
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Tạo phiếu nhập'),
      ),
    );
  }
}
