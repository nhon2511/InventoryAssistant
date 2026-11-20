import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/app/theme/app_colors.dart';
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
    final scheme = Theme.of(context).colorScheme;
    Widget navigation() => Theme(
      data: Theme.of(context).copyWith(
        listTileTheme: ListTileThemeData(
          textColor: scheme.onPrimary,
          iconColor: scheme.onPrimary.withValues(alpha: 0.76),
          selectedColor: scheme.onPrimary,
          selectedTileColor: scheme.primary.withValues(alpha: 0.42),
        ),
      ),
      child: Material(
        color: AppColors.primaryDark,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: scheme.onPrimary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      Icons.warehouse_outlined,
                      color: scheme.onPrimary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMART WMS',
                        style: TextStyle(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'ĐIỀU HÀNH KHO',
                        style: TextStyle(
                          color: scheme.onPrimary.withValues(alpha: 0.72),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.15,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Divider(color: scheme.onPrimary.withValues(alpha: 0.14), height: 1),
            for (final entry in destinations) ...[
              if (entry.$1 == '/' ||
                  entry.$1 == '/products' ||
                  entry.$1 == '/reports' ||
                  entry.$1 == '/batch-scan' ||
                  entry.$1 == '/profile')
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
                  child: Text(
                    switch (entry.$1) {
                      '/' => 'TỔNG QUAN',
                      '/products' => 'HÀNG HÓA & VỊ TRÍ',
                      '/reports' => 'THEO DÕI',
                      '/batch-scan' => 'CÔNG CỤ',
                      _ => 'TÀI KHOẢN',
                    },
                    style: TextStyle(
                      color: scheme.onPrimary.withValues(alpha: 0.64),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.15,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 2,
                ),
                child: ListTile(
                  minLeadingWidth: 22,
                  minVerticalPadding: 9,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                    side: BorderSide(
                      color:
                          (entry.$1 == '/'
                              ? location == '/'
                              : location.startsWith(entry.$1))
                          ? scheme.onPrimary.withValues(alpha: 0.22)
                          : Colors.transparent,
                    ),
                  ),
                  selected: entry.$1 == '/'
                      ? location == '/'
                      : location.startsWith(entry.$1),
                  leading: Icon(entry.$3, size: 20),
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
        leading: wide ? null : const DrawerButton(),
        title: Text(
          _sectionLabel(location),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontSize: 11,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        actions: [
          if (ref.watch(frontendPreviewProvider))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Tooltip(
                message:
                    'Dữ liệu mẫu trong bộ nhớ, được tạo lại khi khởi động.',
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Text(
                    'DỮ LIỆU MẪU',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
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
          Expanded(
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: child,
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : Builder(
              builder: (context) => NavigationBar(
                selectedIndex:
                    location.startsWith('/products') ||
                        location.startsWith('/locations')
                    ? 1
                    : location.startsWith('/inbound')
                    ? 2
                    : location.startsWith('/outbound')
                    ? 3
                    : location == '/'
                    ? 0
                    : 4,
                onDestinationSelected: (index) {
                  if (index == 4) {
                    Scaffold.of(context).openDrawer();
                    return;
                  }
                  context.go(
                    ['/', '/products', '/inbound', '/outbound'][index],
                  );
                },
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
                  NavigationDestination(
                    icon: Icon(Icons.output),
                    label: 'Xuất',
                  ),
                  NavigationDestination(icon: Icon(Icons.menu), label: 'Khác'),
                ],
              ),
            ),
    );
  }

  String _sectionLabel(String location) {
    if (location == '/') return 'VẬN HÀNH KHO';
    if (location.startsWith('/products') || location.startsWith('/locations')) {
      return 'HÀNG HÓA & VỊ TRÍ';
    }
    if (location.startsWith('/inbound')) return 'NHẬN HÀNG';
    if (location.startsWith('/outbound')) return 'SOẠN HÀNG XUẤT';
    if (location == '/ai-draft') return 'PHIẾU TỪ TRỢ LÝ';
    if (location.startsWith('/ai-chat')) return 'TRỢ LÝ KHO';
    if (location.startsWith('/reports')) return 'THEO DÕI';
    if (location.startsWith('/profile')) return 'TÀI KHOẢN';
    return 'SMART WMS';
  }
}
