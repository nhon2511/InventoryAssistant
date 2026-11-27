import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/presentation/widgets/stock_overview_screen.dart';

import 'frontend_widgets_test.dart' show harness;

class _RetryStock extends PreviewRepository {
  int reads = 0;
  @override
  FutureEither<List<InventoryItem>> getAllInventoryItems() async {
    if (reads++ == 0) {
      return const Left(ServerFailure(message: 'private mock detail'));
    }
    return super.getAllInventoryItems();
  }
}

void main() {
  testWidgets(
    'dashboard retries failed stock and manual refresh reloads snapshot',
    (tester) async {
      final repository = _RetryStock();
      addTearDown(repository.dispose);
      await repository.signIn(email: 'admin@preview.local', password: 'test');
      await tester.pumpWidget(harness(repository, const StockOverviewScreen()));
      await tester.pumpAndSettle();
      expect(find.textContaining('Không tải được dữ liệu'), findsOneWidget);
      expect(find.textContaining('private mock detail'), findsNothing);
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Realtime chưa được xác minh'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Tải lại tồn kho'));
      await tester.pumpAndSettle();
      expect(repository.reads, 3);
    },
  );

  testWidgets('dashboard distinguishes an empty snapshot', (tester) async {
    final repository = PreviewRepository();
    addTearDown(repository.dispose);
    repository.stock.clear();
    await repository.signIn(email: 'admin@preview.local', password: 'test');
    await tester.pumpWidget(harness(repository, const StockOverviewScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có số lượng tồn.'), findsOneWidget);
  });
}
