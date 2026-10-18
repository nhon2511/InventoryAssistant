import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wms/app/app.dart';
import 'package:smart_wms/app/router/app_router.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/widgets/scanner_back_button.dart';
import 'package:smart_wms/features/orders/presentation/widgets/order_form_screen.dart';

import 'frontend_widgets_test.dart' show harness;

Future<GoRouter> openApp(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final repository = PreviewRepository();
  addTearDown(repository.dispose);
  await repository.signIn(email: 'admin@preview.local', password: 'test');
  await tester.pumpWidget(harness(repository, const App(), router: true));
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(App)))
      .read(appRouterProvider);
}

void main() {
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'dashboard scan returns with accessible 48px button at $width',
      (tester) async {
        final router = await openApp(tester, width);
        await Scrollable.ensureVisible(
          tester.element(find.text('Tra mã hàng')),
          alignment: 0.5,
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tra mã hàng'));
        await tester.pumpAndSettle();
        expect(router.canPop(), isTrue);
        final back = find.byType(ScannerBackButton);
        expect(back, findsOneWidget);
        final size = tester.getSize(back);
        expect(size.width, greaterThanOrEqualTo(48));
        expect(size.height, greaterThanOrEqualTo(48));
        final semantics = tester.ensureSemantics();
        try {
          expect(find.bySemanticsLabel('Quay lại'), findsWidgets);
        } finally {
          semantics.dispose();
        }
        await tester.tap(back);
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/');
        expect(find.byType(ScannerBackButton), findsNothing);
      },
    );

    for (final type in ['inbound', 'outbound']) {
      testWidgets('$type form survives menu scan and OCR at $width', (
        tester,
      ) async {
        final router = await openApp(tester, width);
        router.go('/$type/new');
        await tester.pumpAndSettle();
        final formState = tester.state(find.byType(OrderFormScreen));
        await tester.enterText(
          find.byType(TextFormField).first,
          'Ghi chú đang nhập',
        );
        final quantities = find.byType(TextFormField);
        await tester.ensureVisible(quantities.at(1));
        await tester.enterText(quantities.at(1), '7');
        if (width < 1000) {
          await tester.tap(find.byType(DrawerButton));
          await tester.pumpAndSettle();
        }
        await tester.ensureVisible(find.text('Tra mã'));
        await tester.tap(find.text('Tra mã'));
        await tester.pumpAndSettle();
        expect(find.text('Rời phiếu chưa lưu?'), findsNothing);
        await tester.enterText(find.byType(TextField).first, '893000000001');
        await tester.tap(find.text('OCR / số lô'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ScannerBackButton));
        await tester.pumpAndSettle();
        expect(find.text('893000000001'), findsOneWidget);
        await tester.tap(find.byType(ScannerBackButton));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          '/$type/new',
        );
        expect(tester.state(find.byType(OrderFormScreen)), same(formState));
        expect(find.text('Ghi chú đang nhập'), findsOneWidget);
        expect(find.text('7'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final entry in {
    '/batch-scan': '/',
    '/ocr-scan': '/batch-scan',
    '/pick-verify/out-1': '/outbound/out-1',
  }.entries) {
    testWidgets('direct and recreated ${entry.key} use contextual fallback', (
      tester,
    ) async {
      final router = await openApp(tester, 390);
      for (var visit = 0; visit < 2; visit++) {
        // go reconstructs the route without the imperative stack, as on reload.
        router.go(entry.key);
        await tester.pumpAndSettle();
        expect(router.canPop(), isFalse);
        await tester.tap(find.byType(ScannerBackButton));
        await tester.pumpAndSettle();
        expect(
          router.routerDelegate.currentConfiguration.uri.path,
          entry.value,
        );
      }
    });
  }

  testWidgets('duplicate scanner cannot return to itself', (tester) async {
    final router = await openApp(tester, 390);
    router.go('/batch-scan');
    await tester.pumpAndSettle();
    unawaited(router.push('/batch-scan'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ScannerBackButton));
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
  });

  testWidgets('pick verification returns to originating order', (tester) async {
    final router = await openApp(tester, 1440);
    router.go('/outbound/out-1');
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithIcon(OutlinedButton, Icons.qr_code_scanner),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ScannerBackButton));
    await tester.pumpAndSettle();
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      '/outbound/out-1',
    );
  });
}
