import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/app/router/route_names.dart';
import 'package:smart_wms/features/ai_assistant/presentation/widgets/ai_chat_screen.dart';
import 'package:smart_wms/features/auth/presentation/widgets/login_screen.dart';
import 'package:smart_wms/features/auth/presentation/widgets/register_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/batch_scan_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/inbound_detail_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/inbound_list_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/ocr_scan_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/location_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/product_detail_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/product_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/stock_overview_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/outbound_detail_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/outbound_list_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/pick_verify_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // TODO: Implement auth redirect guard
      return null;
    },
    routes: [
      ..._authRoutes,
      _mainShellRoute,
      ..._scannerRoutes,
    ],
  );
}



// ── Auth Routes ─────────────────────────────────────────────────────
final _authRoutes = [
  GoRoute(
    path: '/login',
    name: RouteNames.login,
    builder: (context, state) => const LoginScreen(),
  ),
  GoRoute(
    path: '/register',
    name: RouteNames.register,
    builder: (context, state) => const RegisterScreen(),
  ),
];

// ── Scanner Routes (Full screen, outside shell) ─────────────────────
final _scannerRoutes = [
  GoRoute(
    path: '/batch-scan',
    name: RouteNames.batchScan,
    builder: (context, state) => const BatchScanScreen(),
  ),
  GoRoute(
    path: '/ocr-scan',
    name: RouteNames.ocrScan,
    builder: (context, state) => const OcrScanScreen(),
  ),
  GoRoute(
    path: '/pick-verify/:orderId',
    name: RouteNames.pickVerify,
    builder: (context, state) {
      final orderId = state.pathParameters['orderId']!;
      return PickVerifyScreen(orderId: orderId);
    },
  ),
];


// ── Main Shell Route (Bottom Navigation) ────────────────────────────
final _mainShellRoute = ShellRoute(
  builder: (context, state, child) => _MainShell(child: child),
  routes: [
    GoRoute(
      path: '/',
      name: RouteNames.home,
      builder: (context, state) => const StockOverviewScreen(),
    ),
    GoRoute(
      path: '/products',
      name: RouteNames.productList,
      builder: (context, state) => const ProductListScreen(),
      routes: [
        GoRoute(
          path: ':productId',
          name: RouteNames.productDetail,
          builder: (context, state) {
            final productId = state.pathParameters['productId']!;
            return ProductDetailScreen(productId: productId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/locations',
      name: RouteNames.locationList,
      builder: (context, state) => const LocationListScreen(),
    ),
    GoRoute(
      path: '/inbound',
      name: RouteNames.inboundList,
      builder: (context, state) => const InboundListScreen(),
      routes: [
        GoRoute(
          path: ':orderId',
          name: RouteNames.inboundDetail,
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return InboundDetailScreen(orderId: orderId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/outbound',
      name: RouteNames.outboundList,
      builder: (context, state) => const OutboundListScreen(),
      routes: [
        GoRoute(
          path: ':orderId',
          name: RouteNames.outboundDetail,
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OutboundDetailScreen(orderId: orderId);
          },
        ),
      ],
    ),
    GoRoute(
      path: '/ai-chat',
      name: RouteNames.aiChat,
      builder: (context, state) => const AiChatScreen(),
    ),
  ],
);


/// Main app shell with bottom navigation bar.
class _MainShell extends StatelessWidget {
  const _MainShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(context),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Sản phẩm',
          ),
          NavigationDestination(
            icon: Icon(Icons.input_outlined),
            selectedIcon: Icon(Icons.input),
            label: 'Nhập kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.output_outlined),
            selectedIcon: Icon(Icons.output),
            label: 'Xuất kho',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI',
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/products') ||
        location.startsWith('/locations')) {
      return 1;
    }
    if (location.startsWith('/inbound')) return 2;
    if (location.startsWith('/outbound')) return 3;
    if (location.startsWith('/ai-chat')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed(RouteNames.home);
      case 1:
        context.goNamed(RouteNames.productList);
      case 2:
        context.goNamed(RouteNames.inboundList);
      case 3:
        context.goNamed(RouteNames.outboundList);
      case 4:
        context.goNamed(RouteNames.aiChat);
    }
  }
}
