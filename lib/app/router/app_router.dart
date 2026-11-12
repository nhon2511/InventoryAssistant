import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/app/router/main_shell.dart';
import 'package:smart_wms/app/router/route_names.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/ai_assistant/domain/entities/order_draft_preview.dart';
import 'package:smart_wms/features/ai_assistant/presentation/widgets/ai_chat_screen.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/auth/presentation/widgets/login_screen.dart';
import 'package:smart_wms/features/auth/presentation/widgets/profile_screen.dart';
import 'package:smart_wms/features/auth/presentation/widgets/register_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/batch_scan_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/inbound_detail_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/inbound_list_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/ocr_scan_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/location_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/product_detail_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/product_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/stock_overview_screen.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_form_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/outbound_detail_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/outbound_list_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/pick_verify_screen.dart';
import 'package:smart_wms/features/reports/presentation/widgets/reports_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, next) {
      refresh.value++;
    })
    ..onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final location = state.matchedLocation;
      final isPublicRoute = location == '/login' || location == '/register';
      final isAuthLoading =
          authState is AuthInitial || authState is AuthLoading;
      final isAuthenticated = authState is AuthAuthenticated;

      if (isAuthLoading) return isPublicRoute ? null : '/login';

      if (!isAuthenticated && !isPublicRoute) return '/login';
      if (isAuthenticated && isPublicRoute) return '/';
      return null;
    },
    routes: [..._authRoutes, _mainShellRoute, ..._scannerRoutes],
  );
  ref.onDispose(router.dispose);
  return router;
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
  builder: (context, state, child) => MainShell(child: child),
  routes: [
    GoRoute(
      path: '/ai-draft',
      onExit: (context, state) => confirmOrderExit(context),
      redirect: (_, state) =>
          state.extra is OrderDraftPreview ? null : '/ai-chat',
      builder: (context, state) {
        final draft = state.extra! as OrderDraftPreview;
        return OrderFormScreen(
          type: draft.type,
          initialItems: draft.items,
          initialNote: draft.note,
        );
      },
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
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
          path: 'new',
          onExit: (context, state) => confirmOrderExit(context),
          builder: (context, state) =>
              const OrderFormScreen(type: OrderType.inbound),
        ),
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
          path: 'new',
          onExit: (context, state) => confirmOrderExit(context),
          builder: (context, state) =>
              const OrderFormScreen(type: OrderType.outbound),
        ),
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
    GoRoute(
      path: '/reports',
      name: RouteNames.reports,
      builder: (context, state) => const ReportsScreen(),
    ),
  ],
);
