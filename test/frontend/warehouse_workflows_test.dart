import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/usecases/maintain_inventory_usecase.dart';
import 'package:smart_wms/features/orders/data/repositories/pending_order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/usecases/order_workspace_usecase.dart';

const staff = Profile(
  id: 'preview-staff',
  fullName: 'Nhân viên',
  role: UserRole.staff,
);
const admin = Profile(
  id: 'preview-admin',
  fullName: 'Admin',
  role: UserRole.admin,
);
WarehouseOrderItem line(int count) => WarehouseOrderItem(
  id: 'line',
  orderId: '',
  productId: 'p-1',
  locationId: 'l-1',
  expectedQuantity: count,
  actualQuantity: 0,
);

void main() {
  late PreviewRepository repository;
  setUp(() => repository = PreviewRepository());
  tearDown(() => repository.dispose());
  test('staff list and detail cannot expose another user order', () async {
    final usecase = ReadOrdersUseCase(repository, repository);
    final orders = (await usecase.list(
      OrderType.inbound,
      staff,
    )).getOrElse((_) => []);
    expect(orders.map((o) => o.id), ['in-1']);
    expect(
      (await usecase.detail(OrderType.inbound, 'other-1', staff)).isLeft(),
      isTrue,
    );
    expect(
      (await usecase.detail(OrderType.inbound, 'other-1', admin)).isRight(),
      isTrue,
    );
  });
  test('outbound validation sums duplicate lines per location and subtracts reserved stock', () {
    expect(
      OrderWorkspaceUseCase.validate(OrderType.outbound, [
        line(40),
        line(31),
      ], repository.stock),
      contains('vượt tồn'),
    );
    expect(
      OrderWorkspaceUseCase.validate(OrderType.outbound, [
        line(70),
      ], repository.stock),
      isNull,
    );
    expect(
      OrderWorkspaceUseCase.validate(OrderType.inbound, [
        line(0),
      ], repository.stock),
      isNotNull,
    );
    expect(
      OrderWorkspaceUseCase.validate(OrderType.inbound, [], repository.stock),
      isNotNull,
    );
  });
  test('draft save is idempotent and approval never modifies stock', () async {
    final usecase = OrderWorkspaceUseCase(repository);
    final first = await usecase.save(
      type: OrderType.inbound,
      profile: staff,
      items: [line(10)],
      requestId: 'same-request',
    );
    final second = await usecase.save(
      type: OrderType.inbound,
      profile: staff,
      items: [line(10)],
      requestId: 'same-request',
    );
    expect(first, second);
    final order = first.getOrElse((_) => throw StateError('expected draft'));
    final before = repository.stock.map((s) => s.quantityOnHand).toList();
    expect(
      (await usecase.review(order, staff, approve: true)).isLeft(),
      isTrue,
    );
    final approved = await usecase.review(order, admin, approve: true);
    expect(
      approved.getOrElse((_) => throw StateError('expected review')).status,
      OrderStatus.confirmed,
    );
    expect(repository.stock.map((s) => s.quantityOnHand), before);
    expect(
      (await usecase.review(order, admin, approve: false)).isLeft(),
      isTrue,
    );
  });
  test('pending backend cannot pretend to save a valid draft', () async {
    final result =
        await const OrderWorkspaceUseCase(PendingOrderWorkflowRepository())
            .save(
              type: OrderType.inbound,
              profile: staff,
              items: [line(1)],
              requestId: 'real',
            );
    expect(result.isLeft(), isTrue);
  });
  test(
    'maintenance checks role, duplicate identifiers and referenced deletion',
    () async {
      final usecase = MaintainInventoryUseCase(repository);
      const product = Product(
        id: 'new',
        sku: 'BH-001',
        barcode: 'new',
        name: 'Mới',
        unit: 'cái',
        minSafetyStock: 0,
      );
      expect(
        (await usecase.saveProduct(product, UserRole.staff)).isLeft(),
        isTrue,
      );
      expect(
        (await usecase.saveProduct(product, UserRole.admin)).isLeft(),
        isTrue,
      );
      expect(
        (await usecase.deleteProduct('p-1', UserRole.admin)).isLeft(),
        isTrue,
      );
      expect(
        (await usecase.deleteLocation('l-1', UserRole.admin)).isLeft(),
        isTrue,
      );
    },
  );
}
