import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_labels.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({required this.type, super.key});
  final OrderType type;
  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String query = '';
  OrderStatus? status;
  @override
  Widget build(BuildContext context) {
    final inbound = widget.type == OrderType.inbound;
    final path = inbound ? '/inbound' : '/outbound';
    final auth = ref.watch(authControllerProvider);
    final staff =
        auth is AuthAuthenticated && !auth.profile.role.isManagerOrAbove;
    return Scaffold(
      body: Padding(
        padding: workspacePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WorkspaceHeader(
              title: inbound ? 'Danh sách phiếu nhập' : 'Danh sách phiếu xuất',
              description: 'Tra cứu phiếu và theo dõi tiến độ xử lý.',
              actions: [
                FilledButton.icon(
                  onPressed: () => context.go('$path/new'),
                  icon: const Icon(Icons.add),
                  label: Text(inbound ? 'Tạo phiếu nhập' : 'Tạo phiếu xuất'),
                ),
              ],
            ),
            if (staff)
              const Padding(
                padding: EdgeInsets.all(8),
                child: Text('Các phiếu do bạn tạo'),
              ),
            LayoutBuilder(
              builder: (context, constraints) {
                final search = TextField(
                  controller: searchController,
                  decoration: const InputDecoration(
                    labelText: 'Tìm mã phiếu hoặc ghi chú',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => query = v),
                );
                final filter = DropdownButtonFormField<OrderStatus>(
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  key: ValueKey(status),
                  initialValue: status,
                  isExpanded: true,
                  menuMaxHeight: 320,
                  items: [
                    const DropdownMenuItem(child: Text('Tất cả')),
                    for (final s in OrderStatus.values)
                      DropdownMenuItem(
                        value: s,
                        child: Text(orderStatusLabel(s)),
                      ),
                  ],
                  onChanged: (v) => setState(() => status = v),
                );
                return constraints.maxWidth >= 640
                    ? Row(
                        children: [
                          SizedBox(
                            width: constraints.maxWidth > 900 ? 420 : 320,
                            child: search,
                          ),
                          const SizedBox(width: 16),
                          SizedBox(width: 220, child: filter),
                        ],
                      )
                    : Column(
                        children: [search, const SizedBox(height: 16), filter],
                      );
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AsyncPanel(
                value: ref.watch(ordersProvider(widget.type)),
                onRetry: () => ref.invalidate(ordersProvider(widget.type)),
                builder: (orders) {
                  final filtered = orders
                      .where(
                        (o) =>
                            (status == null || o.status == status) &&
                            '${o.orderCode} ${o.note ?? ""}'
                                .toLowerCase()
                                .contains(query.toLowerCase()),
                      )
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${filtered.length} kết quả',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 40,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      orders.isEmpty
                                          ? 'Chưa có phiếu nào'
                                          : 'Không tìm thấy phiếu phù hợp',
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () => setState(() {
                                        query = '';
                                        status = null;
                                        searchController.clear();
                                      }),
                                      child: const Text('Xóa bộ lọc'),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: () async {
                                  ref.invalidate(ordersProvider(widget.type));
                                  await ref.read(
                                    ordersProvider(widget.type).future,
                                  );
                                },
                                child: LayoutBuilder(
                                  builder: (context, constraints) =>
                                      constraints.maxWidth >= 900
                                      ? SingleChildScrollView(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          child: SizedBox(
                                            width: constraints.maxWidth,
                                            child: Card(
                                              margin: EdgeInsets.zero,
                                              child: DataTable(
                                                showCheckboxColumn: false,
                                                dataRowColor:
                                                    WidgetStateProperty.resolveWith(
                                                      (states) =>
                                                          states.contains(
                                                                WidgetState
                                                                    .hovered,
                                                              ) ||
                                                              states.contains(
                                                                WidgetState
                                                                    .focused,
                                                              )
                                                          ? Theme.of(context)
                                                                .colorScheme
                                                                .primary
                                                                .withValues(
                                                                  alpha: .06,
                                                                )
                                                          : null,
                                                    ),
                                                headingRowColor:
                                                    WidgetStatePropertyAll(
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .surfaceContainerLow,
                                                    ),
                                                horizontalMargin: 16,
                                                columnSpacing: 16,
                                                dataRowMinHeight: 64,
                                                dataRowMaxHeight: 80,
                                                columns: const [
                                                  DataColumn(
                                                    label: Text('Mã phiếu'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Ngày tạo'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Trạng thái'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Ghi chú'),
                                                  ),
                                                  DataColumn(
                                                    label: Text('Thao tác'),
                                                  ),
                                                ],
                                                rows: [
                                                  for (final order in filtered)
                                                    DataRow(
                                                      onSelectChanged: (_) =>
                                                          context.go(
                                                            '$path/${order.id}',
                                                          ),
                                                      cells: [
                                                        DataCell(
                                                          TextButton(
                                                            onPressed: () =>
                                                                context.go(
                                                                  '$path/${order.id}',
                                                                ),
                                                            child: Text(
                                                              order.orderCode,
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          Text(
                                                            order.createdAt ==
                                                                    null
                                                                ? '—'
                                                                : DateFormat(
                                                                    'dd/MM/yyyy',
                                                                  ).format(
                                                                    order
                                                                        .createdAt!,
                                                                  ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          OrderStatusBadge(
                                                            status:
                                                                order.status,
                                                          ),
                                                        ),
                                                        DataCell(
                                                          SizedBox(
                                                            width:
                                                                (constraints.maxWidth -
                                                                        590)
                                                                    .clamp(
                                                                      80,
                                                                      360,
                                                                    )
                                                                    .toDouble(),
                                                            child: Text(
                                                              order.note ?? '—',
                                                              maxLines: 2,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ),
                                                        DataCell(
                                                          IconButton(
                                                            tooltip:
                                                                'Xem chi tiết',
                                                            onPressed: () =>
                                                                context.go(
                                                                  '$path/${order.id}',
                                                                ),
                                                            icon: const Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        )
                                      : ListView.separated(
                                          itemCount: filtered.length,
                                          separatorBuilder: (_, _) =>
                                              const Divider(height: 1),
                                          itemBuilder: (context, index) {
                                            final order = filtered[index];
                                            return Card(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                              child: InkWell(
                                                onTap: () => context.go(
                                                  '$path/${order.id}',
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    16,
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              order.orderCode,
                                                              style:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .textTheme
                                                                      .titleMedium,
                                                            ),
                                                          ),
                                                          const Icon(
                                                            Icons.chevron_right,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Wrap(
                                                        spacing: 12,
                                                        runSpacing: 8,
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          OrderStatusBadge(
                                                            status:
                                                                order.status,
                                                          ),
                                                          Text(
                                                            order.createdAt ==
                                                                    null
                                                                ? 'Chưa rõ ngày'
                                                                : DateFormat(
                                                                    'dd/MM/yyyy',
                                                                  ).format(
                                                                    order
                                                                        .createdAt!,
                                                                  ),
                                                          ),
                                                        ],
                                                      ),
                                                      if (order
                                                              .note
                                                              ?.isNotEmpty ??
                                                          false) ...[
                                                        const SizedBox(
                                                          height: 12,
                                                        ),
                                                        Text(order.note!),
                                                      ],
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
