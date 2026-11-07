import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/app/theme/theme_controller.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/widgets/confirm_dialog.dart';
import 'package:smart_wms/core/widgets/workspace_layout.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final profile = auth is AuthAuthenticated ? auth.profile : null;
    return Scaffold(
      body: WorkspaceContent(
        maxWidth: 760,
        child: ListView(
          padding: workspacePadding(context),
          children: [
            const WorkspaceHeader(
              title: 'Hồ sơ & giao diện',
              description:
                  'Thông tin tài khoản và tùy chọn hiển thị trong phiên.',
            ),
            Text(
              profile?.fullName ?? 'Đang tải hồ sơ',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.badge_outlined),
              title: const Text('Vai trò'),
              subtitle: Text(switch (profile?.role) {
                UserRole.admin => 'Quản trị viên',
                UserRole.manager => 'Quản lý kho',
                UserRole.staff => 'Nhân viên',
                null => '—',
              }),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Điện thoại'),
              subtitle: Text(profile?.phoneNumber ?? 'Chưa cung cấp'),
            ),
            const ListTile(
              title: Text('Chỉnh sửa hồ sơ'),
              subtitle: Text(
                'Chưa khả dụng: cần contract cập nhật hồ sơ từ backend.',
              ),
            ),
            const Divider(),
            const Text('Giao diện (áp dụng trong phiên hiện tại)'),
            const SizedBox(height: 12),
            DropdownButtonFormField<ThemeMode>(
              initialValue: ref.watch(themeModeProvider),
              decoration: const InputDecoration(labelText: 'Chế độ màu'),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Theo hệ thống'),
                ),
                DropdownMenuItem(value: ThemeMode.light, child: Text('Sáng')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('Tối')),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).mode = mode;
                }
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: auth is AuthLoading
                  ? null
                  : () async {
                      final confirmed = await ConfirmDialog.show(
                        context,
                        title: 'Đăng xuất?',
                        content: 'Bạn sẽ quay lại màn hình đăng nhập.',
                      );
                      if (confirmed && context.mounted) {
                        await ref
                            .read(authControllerProvider.notifier)
                            .signOut();
                      }
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Đăng xuất'),
            ),
            if (auth is AuthError)
              Text(
                'Không thể đăng xuất. Vui lòng thử lại.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
