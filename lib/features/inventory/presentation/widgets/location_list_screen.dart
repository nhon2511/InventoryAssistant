import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/widgets/async_panel.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/location_controller.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/inventory_edit_dialog.dart';

class LocationListScreen extends ConsumerStatefulWidget {
  const LocationListScreen({super.key});
  @override
  ConsumerState<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends ConsumerState<LocationListScreen> {
  String query = '';
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final admin = auth is AuthAuthenticated && auth.profile.role.isAdmin;
    return Scaffold(
      body: WorkspaceContent(
        child: Column(
          children: [
            Padding(
              padding: workspacePadding(context).copyWith(bottom: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  WorkspaceHeader(
                    title: 'Vị trí lưu trữ',
                    description: 'Tra cứu khu, dãy, kệ và ô chứa hàng.',
                    actions: [
                      if (admin)
                        FilledButton.icon(
                          onPressed: () => showDialog<void>(
                            context: context,
                            builder: (_) =>
                                const InventoryEditDialog(isLocation: true),
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
                        labelText: 'Tìm khu, dãy, kệ, ô hoặc mã vạch',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AsyncPanel(
                value: ref.watch(locationControllerProvider),
                onRetry: () => ref.invalidate(locationControllerProvider),
                builder: (locations) {
                  final filtered = locations
                      .where(
                        (l) => '${l.displayLabel} ${l.locationBarcode}'
                            .toLowerCase()
                            .contains(query.toLowerCase()),
                      )
                      .toList();
                  return Column(
                    children: [
                      Padding(
                        padding: workspacePadding(context)
                            .copyWith(top: 0, bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('${filtered.length} vị trí'),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: workspacePadding(context),
                                  child: const Text(
                                    'Chưa có vị trí phù hợp. Hãy đổi từ khóa tìm kiếm.',
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.symmetric(
                                  horizontal: workspacePadding(context).left,
                                ),
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemCount: filtered.length,
                                itemBuilder: (context, index) {
                                  final l = filtered[index];
                                  return ListTile(
                                    leading: const Icon(
                                      Icons.location_on_outlined,
                                    ),
                                    title: Text(l.displayLabel),
                                    subtitle: Text(
                                      'Mã: ${l.locationBarcode}\nSức chứa: ${l.maxCapacityKg == null ? "Chưa cung cấp" : "${l.maxCapacityKg} kg"}',
                                    ),
                                    isThreeLine: true,
                                    onTap: () => showDialog<void>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Text(l.displayLabel),
                                        content: Text(
                                          'Khu: ${l.zoneCode}\nDãy: ${l.aisleCode}\nKệ: ${l.rackCode}\nÔ: ${l.binCode}\nMã vạch: ${l.locationBarcode}',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Đóng'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    trailing: admin
                                        ? PopupMenuButton<String>(
                                            enabled: !busy,
                                            tooltip: 'Thao tác vị trí',
                                            onSelected: (action) async {
                                              if (action == 'edit') {
                                                await showDialog<void>(
                                                  context: context,
                                                  builder: (_) =>
                                                      InventoryEditDialog(
                                                        isLocation: true,
                                                        location: l,
                                                      ),
                                                );
                                                return;
                                              }
                                              if (!await ConfirmDialog.show(
                                                context,
                                                title: 'Xóa vị trí?',
                                                content: 'Chỉ được xóa vị trí không có tồn và tham chiếu. Backend phải xác nhận điều kiện này.',
                                                isDestructive: true,
                                              )) {
                                                return;
                                              }
                                              if (!mounted) return;
                                              setState(() => busy = true);
                                              final result = await ref
                                                  .read(
                                                    maintainInventoryProvider,
                                                  )
                                                  .deleteLocation(
                                                    l.id,
                                                    auth.profile.role,
                                                  );
                                              if (!mounted) return;
                                              setState(() => busy = false);
                                              result.fold(
                                                (f) =>
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          f.message,
                                                        ),
                                                      ),
                                                    ),
                                                (_) {
                                                  ref.invalidate(
                                                    locationControllerProvider,
                                                  );
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            'Đã xóa vị trí.',
                                                          ),
                                                        ),
                                                      );
                                                },
                                              );
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                value: 'edit',
                                                child: Text('Sửa'),
                                              ),
                                              PopupMenuItem(
                                                value: 'delete',
                                                child: Text('Xóa'),
                                              ),
                                            ],
                                          )
                                        : null,
                                  );
                                },
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
