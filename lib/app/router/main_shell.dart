import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/preview/preview_mode.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_form_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({required this.child, super.key});
  final Widget child;

  static const destinations = <(String, String, IconData)>[
    ('/', 'Tổng quan', Icons.dashboard_outlined),
    ('/products', 'Sản phẩm', Icons.inventory_2_outlined),
    ('/locations', 'Vị trí', Icons.location_on_outlined),
    ('/inbound', 'Nhập kho', Icons.input),
    ('/outbound', 'Xuất kho', Icons.output),
    ('/reports', 'Báo cáo', Icons.assessment_outlined),
    ('/batch-scan', 'Tra mã', Icons.qr_code_scanner),
    ('/ai-chat', 'Trợ lý AI', Icons.smart_toy_outlined),
    ('/profile', 'Tài khoản', Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final auth = ref.watch(authControllerProvider);
    final profile = auth is AuthAuthenticated ? auth.profile : null;
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    Widget navigation() => Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: const ListTileThemeData(
          textColor: Color(0xFFD5DEEC),
          iconColor: Color(0xFFD5DEEC),
          selectedColor: Colors.white,
          selectedTileColor: Color(0xFF2563EB),
        ),
      ),
      child: Material(
        color: const Color(0xFF14253D),
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'SMART WMS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
            ),
            for (final entry in destinations) ...[
              if (entry.$1 == '/' ||
                  entry.$1 == '/products' ||
                  entry.$1 == '/reports' ||
                  entry.$1 == '/profile')
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Text(
                    switch (entry.$1) {
                      '/' => 'TỔNG QUAN',
                      '/products' => 'QUẢN LÝ KHO',
                      '/reports' => 'CÔNG CỤ',
                      _ => 'CÁ NHÂN',
                    },
                    style: const TextStyle(
                      color: Color(0xFFBBCADD),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  selected: entry.$1 == '/'
                      ? location == '/'
                      : location.startsWith(entry.$1),
                  leading: Icon(entry.$3),
                  title: Text(entry.$2),
                  onTap: () {
                    if (!wide) Navigator.of(context).pop();
                    if (entry.$1 == '/batch-scan') {
                      context.push(entry.$1);
                    } else {
                      context.go(entry.$1);
                    }
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          destinations
                  .where(
                    (e) => e.$1 == '/'
                        ? location == '/'
                        : location.startsWith(e.$1),
                  )
                  .firstOrNull
                  ?.$2 ??
              'Smart WMS',
        ),
        actions: [
          if (ref.watch(frontendPreviewProvider))
            const Tooltip(
              message: 'Dữ liệu mẫu trong bộ nhớ, được tạo lại khi khởi động.',
              child: Chip(
                label: Text('Dữ liệu mẫu'),
                visualDensity: VisualDensity.compact,
              ),
            ),
          PopupMenuButton<String>(
            tooltip: 'Menu tài khoản',
            onSelected: (value) async {
              if (value == 'logout') {
                if (await confirmOrderExit(context)) {
                  await ref.read(authControllerProvider.notifier).signOut();
                }
              } else {
                context.go('/profile');
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'profile', child: Text('Hồ sơ')),
              PopupMenuItem(value: 'logout', child: Text('Đăng xuất')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle_outlined),
                  if (wide) ...[
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(profile?.fullName ?? 'Tài khoản'),
                        Text(switch (profile?.role) {
                          UserRole.admin => 'Quản trị viên',
                          UserRole.manager => 'Quản lý kho',
                          UserRole.staff => 'Nhân viên',
                          null => '',
                        }, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ],
                  const Icon(Icons.expand_more),
                ],
              ),
            ),
          ),
        ],
      ),
      drawer: wide ? null : Drawer(child: SafeArea(child: navigation())),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 240,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: navigation(),
              ),
            ),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex:
                  location.startsWith('/products') ||
                      location.startsWith('/locations')
                  ? 1
                  : location.startsWith('/inbound')
                  ? 2
                  : location.startsWith('/outbound')
                  ? 3
                  : 0,
              onDestinationSelected: (index) => context.go(
                ['/', '/products', '/inbound', '/outbound'][index],
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  label: 'Tổng quan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Hàng hóa',
                ),
                NavigationDestination(icon: Icon(Icons.input), label: 'Nhập'),
                NavigationDestination(icon: Icon(Icons.output), label: 'Xuất'),
              ],
            ),
    );
  }
}
