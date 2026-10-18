import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/app/app.dart';
import 'package:smart_wms/app/theme/app_theme.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/presentation/widgets/inbound_list_screen.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/stock_overview_screen.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_form_screen.dart';

import 'frontend_widgets_test.dart' show harness;

class _RetryOrders extends PreviewRepository {
  final firstRead = Completer<Either<Failure, List<WarehouseOrder>>>();
  int reads = 0;
  @override
  FutureEither<List<WarehouseOrder>> getInboundOrders() =>
      reads++ == 0 ? firstRead.future : super.getInboundOrders();
}

class _FailedSave extends PreviewRepository {
  int saves = 0;
  @override
  FutureEither<WarehouseOrder> saveDraft({
    required OrderType type,
    required String createdBy,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  }) async {
    saves++;
    return const Left(
      ServerFailure(message: 'Không thể lưu phiếu. Vui lòng thử lại.'),
    );
  }
}

class _PendingSave extends PreviewRepository {
  int saves = 0;
  final result = Completer<Either<Failure, WarehouseOrder>>();
  @override
  FutureEither<WarehouseOrder> saveDraft({
    required OrderType type,
    required String createdBy,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  }) {
    saves++;
    return result.future;
  }
}

void main() {
  testWidgets('saving shows loading and disables repeated submission', (
    tester,
  ) async {
    final repository = _PendingSave();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(
      harness(
        repository,
        OrderFormScreen(
          type: OrderType.inbound,
          initialItems: repository.orders.first.items,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận lưu nháp'));
    await tester.pump();
    expect(find.text('Đang lưu...'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(button.onPressed, isNull);
    expect(repository.saves, 1);
    repository.result.complete(
      const Left(ServerFailure(message: 'Không thể lưu phiếu.')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận lưu nháp'), findsOneWidget);
  });
  testWidgets('inbound loading, localized error and retry recover results', (
    tester,
  ) async {
    final repository = _RetryOrders();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(harness(repository, const InboundListScreen()));
    await tester.pump();
    await tester.pump();
    expect(find.text('Đang tải dữ liệu...'), findsOneWidget);
    repository.firstRead.complete(
      const Left(ServerFailure(message: 'private adapter details')),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('private adapter'), findsNothing);
    expect(find.textContaining('Không tải được dữ liệu'), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('PN-XEM-001'), findsOneWidget);
  });
  testWidgets('empty inbound list retains create action', (tester) async {
    final repository = PreviewRepository()..orders.clear();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(harness(repository, const InboundListScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có phiếu nào'), findsOneWidget);
    expect(find.text('Tạo phiếu nhập'), findsOneWidget);
  });
  testWidgets('failed save keeps draft and does not show success', (
    tester,
  ) async {
    final repository = _FailedSave();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(
      harness(
        repository,
        OrderFormScreen(
          type: OrderType.inbound,
          initialItems: repository.orders.first.items,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận lưu nháp'));
    await tester.pumpAndSettle();
    expect(repository.saves, 1);
    await tester.scrollUntilVisible(
      find.text('Không thể lưu phiếu. Vui lòng thử lại.'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(repository.saves, 1);
    expect(repository.orders.length, 3);
    expect(find.textContaining('Đã lưu phiếu nháp'), findsNothing);
    expect(find.text('12'), findsOneWidget);
  });
  for (final screen in [
    const StockOverviewScreen(),
    const InboundListScreen(),
    const OrderFormScreen(type: OrderType.inbound),
  ]) {
    testWidgets('${screen.runtimeType} dark theme at 390', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PreviewRepository(showcase: true);
      addTearDown(repository.dispose);
      await repository.signIn(email: 'admin@preview.local', password: 'test');
      await tester.pumpWidget(
        harness(repository, Theme(data: AppTheme.dark, child: screen)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final width in [390.0, 820.0, 1440.0]) {
    for (final screen in [
      const StockOverviewScreen(),
      const InboundListScreen(),
      const OrderFormScreen(type: OrderType.inbound),
    ]) {
      testWidgets(
        '${screen.runtimeType} long fixtures at $width and large text',
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = PreviewRepository(showcase: true);
          addTearDown(repository.dispose);
          await repository.signIn(
            email: 'admin@preview.local',
            password: 'test',
          );
          await tester.pumpWidget(
            harness(
              repository,
              MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 900),
                  textScaler: const TextScaler.linear(1.3),
                ),
                child: screen,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets('desktop inbound search and status filter preserve results', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = PreviewRepository(showcase: true);
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(harness(repository, const InboundListScreen()));
    await tester.pumpAndSettle();
    expect(find.byType(DataTable), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<OrderStatus>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đang xử lý').last);
    await tester.pumpAndSettle();
    expect(find.text('1 kết quả'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'không tồn tại');
    await tester.pumpAndSettle();
    expect(find.text('Không tìm thấy phiếu phù hợp'), findsOneWidget);
    await tester.tap(find.text('Xóa bộ lọc'));
    await tester.pumpAndSettle();
    expect(find.text('5 kết quả'), findsOneWidget);
  });
  testWidgets('deleting first line retains second line quantity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(
      harness(repository, const OrderFormScreen(type: OrderType.inbound)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thêm dòng hàng'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(1), '12');
    await tester.enterText(find.byType(TextFormField).at(2), '37');
    await tester.tap(find.byTooltip('Xóa dòng').first);
    await tester.pumpAndSettle();
    expect(find.text('37'), findsOneWidget);
    expect(find.text('12'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'shell navigation confirms unsaved order and cancel retains note',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = PreviewRepository();
      addTearDown(repository.dispose);
      await repository.signIn(email: 'admin@preview.local', password: 'test');
      await tester.pumpWidget(harness(repository, const App(), router: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tạo phiếu nhập'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Ghi chú chưa lưu',
      );
      await tester.tap(find.text('Sản phẩm').first);
      await tester.pumpAndSettle();
      expect(find.text('Rời phiếu chưa lưu?'), findsOneWidget);
      await tester.tap(find.text('Tiếp tục nhập'));
      await tester.pumpAndSettle();
      expect(find.text('Ghi chú chưa lưu'), findsOneWidget);
    },
  );
}
