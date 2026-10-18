import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/app/app.dart';
import 'package:smart_wms/app/theme/app_theme.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/core/di/auth_providers.dart';
import 'package:smart_wms/core/di/inbound_providers.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/di/outbound_providers.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/preview/preview_ai_repository.dart';
import 'package:smart_wms/core/preview/preview_mode.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/ai_assistant/presentation/widgets/ai_chat_screen.dart';
import 'package:smart_wms/features/auth/presentation/widgets/profile_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/barcode_lookup_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/inbound_list_screen.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/ocr_scan_screen.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/inventory_edit_dialog.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/location_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/product_detail_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/product_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/stock_overview_screen.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_detail_screen.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_form_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/outbound_list_screen.dart';
import 'package:smart_wms/features/outbound/presentation/widgets/pick_verify_screen.dart';
import 'package:smart_wms/features/reports/presentation/widgets/reports_screen.dart';

Widget harness(
  PreviewRepository repository,
  Widget child, {
  bool router = false,
}) => ProviderScope(
  overrides: [
    authRepositoryProvider.overrideWithValue(repository),
    aiAssistantRepositoryProvider.overrideWithValue(
      PreviewAiRepository(repository),
    ),
    inventoryRepositoryProvider.overrideWithValue(repository),
    inboundRepositoryProvider.overrideWithValue(repository),
    outboundRepositoryProvider.overrideWithValue(repository),
    inventoryMaintenanceRepositoryProvider.overrideWithValue(repository),
    orderWorkflowRepositoryProvider.overrideWithValue(repository),
    frontendPreviewProvider.overrideWithValue(true),
  ],
  child: router ? child : MaterialApp(theme: AppTheme.light, home: child),
);

class _RetryInventory extends PreviewRepository {
  int reads = 0;
  @override
  FutureEither<List<Product>> getAllProducts() async {
    if (reads++ == 0) {
      return const Left(ServerFailure(message: 'private internal mock'));
    }
    return super.getAllProducts();
  }
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'auth pages stay usable at $width and register returns to login',
      (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = PreviewRepository();
        addTearDown(repository.dispose);
        await tester.pumpWidget(harness(repository, const App(), router: true));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Chưa có tài khoản? Đăng ký'));
        await tester.pumpAndSettle();
        expect(find.text('Tạo tài khoản Smart WMS'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('Quay lại đăng nhập'));
        await tester.pumpAndSettle();
        expect(find.text('Smart WMS'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  final screens = <String, Widget>{
    'dashboard': const StockOverviewScreen(),
    'product detail': const ProductDetailScreen(productId: 'p-1'),
    'locations': const LocationListScreen(),
    'inbound list': const InboundListScreen(),
    'outbound list': const OutboundListScreen(),
    'order detail': const OrderDetailScreen(
      type: OrderType.inbound,
      orderId: 'in-1',
    ),
    'order form': const OrderFormScreen(type: OrderType.outbound),
    'reports': const ReportsScreen(),
    'barcode': const BarcodeLookupScreen(),
    'OCR text': const OcrScanScreen(),
    'pick verification': const PickVerifyScreen(orderId: 'out-1'),
    'AI chat': const AiChatScreen(),
    'profile': const ProfileScreen(),
  };
  for (final width in [390.0, 1440.0]) {
    for (final entry in screens.entries) {
      testWidgets('${entry.key} renders without overflow at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = PreviewRepository();
        addTearDown(repository.dispose);
        await repository.signIn(email: 'admin@preview.local', password: 'test');
        await tester.pumpWidget(harness(repository, entry.value));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
  testWidgets('inventory error is localized and retry restores data', (
    tester,
  ) async {
    final repository = _RetryInventory();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'staff@preview.local', password: 'test');
    await tester.pumpWidget(harness(repository, const ProductListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('private internal'), findsNothing);
    expect(find.textContaining('Không tải được dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Găng tay bảo hộ'), findsOneWidget);
    expect(find.text('Thêm'), findsNothing);
  });
  testWidgets('empty product state has useful recovery text', (tester) async {
    final repository = PreviewRepository();
    repository.products.clear();
    addTearDown(repository.dispose);
    await tester.pumpWidget(harness(repository, const ProductListScreen()));
    await tester.pumpAndSettle();
    expect(find.textContaining('Không có sản phẩm phù hợp'), findsOneWidget);
  });
  testWidgets('admin saves a new valid fixture product through usecase', (
    tester,
  ) async {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(harness(repository, const ProductListScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    for (final entry in [
      'Vật tư mới',
      'NEW-001',
      'NEW-BARCODE',
      'cái',
      '5',
    ].indexed) {
      await tester.enterText(fields.at(entry.$1), entry.$2);
    }
    await tester.tap(find.text('Lưu'));
    await tester.pumpAndSettle();
    expect(repository.products.last.name, 'Vật tư mới');
    expect(find.byType(InventoryEditDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [390.0, 1440.0]) {
    testWidgets('product search and inventory form validation at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      await repository.signIn(email: 'admin@preview.local', password: 'test');
      await tester.pumpWidget(harness(repository, const ProductListScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Găng tay bảo hộ'), findsOneWidget);
      await tester.enterText(find.byType(TextField).first, 'DG-002');
      await tester.pumpAndSettle();
      expect(find.text('Găng tay bảo hộ'), findsNothing);
      expect(find.text('Băng keo đóng thùng'), findsOneWidget);
      await tester.tap(find.text('Thêm'));
      await tester.pumpAndSettle();
      expect(find.byType(InventoryEditDialog), findsOneWidget);
      await tester.tap(find.text('Lưu'));
      await tester.pumpAndSettle();
      expect(find.text('Trường bắt buộc'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('order form rejects required selections and zero quantity', (
    tester,
  ) async {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'staff@preview.local', password: 'test');
    await tester.pumpWidget(
      harness(repository, const OrderFormScreen(type: OrderType.inbound)),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Xác nhận lưu nháp'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Xác nhận lưu nháp'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn sản phẩm'), findsOneWidget);
    expect(find.text('Chọn vị trí'), findsOneWidget);
    expect(find.text('Nhập số nguyên lớn hơn 0'), findsOneWidget);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpAndSettle();
    expect(find.text('Chọn sản phẩm'), findsOneWidget);
    expect(find.text('Chọn vị trí'), findsOneWidget);
    expect(find.text('Nhập số nguyên lớn hơn 0'), findsOneWidget);
    expect(repository.orders.length, 3);
    expect(tester.takeException(), isNull);
  });
  testWidgets('login guard, profile navigation and logout use stable router', (
    tester,
  ) async {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    await tester.pumpWidget(harness(repository, const App(), router: true));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'staff@preview.local',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'test');
    await tester.tap(find.text('Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsNothing);
    await tester.tap(find.byTooltip('Menu tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hồ sơ'));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ & giao diện'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Đăng xuất'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Đăng xuất'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
