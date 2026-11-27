import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/auth/domain/entities/profile.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/usecases/order_workspace_usecase.dart';

class _ConfirmRepo extends PreviewRepository {
  int calls = 0;
  @override
  FutureEither<OrderConfirmationOutcome> confirm({
    required String orderId,
    required OrderType type,
    required Map<String, int> actualQuantities,
    required String idempotencyKey,
  }) async {
    calls++;
    return const Right(OrderConfirmationOutcome.applied);
  }
}

void main() {
  final repo = _ConfirmRepo();
  tearDownAll(repo.dispose);
  const owner = Profile(
    id: 'actor',
    fullName: 'Manager',
    role: UserRole.manager,
  );
  const staff = Profile(id: 'actor', fullName: 'Staff', role: UserRole.staff);
  const line = WarehouseOrderItem(
    id: 'line',
    orderId: 'order',
    productId: 'product',
    locationId: 'location',
    expectedQuantity: 5,
    actualQuantity: 0,
  );
  const order = WarehouseOrder(
    id: 'order',
    orderCode: 'IN-1',
    type: OrderType.inbound,
    status: OrderStatus.confirmed,
    createdBy: 'actor',
    items: [line],
  );
  final usecase = OrderWorkspaceUseCase(repo);

  test('accepts positive partial actual quantity for owner manager', () async {
    final result = await usecase.confirm(
      order,
      owner,
      actualQuantities: {'line': 3},
      idempotencyKey: 'key',
    );
    expect(result.getRight().toNullable(), OrderConfirmationOutcome.applied);
    expect(repo.calls, 1);
  });

  test('rejects staff, other owner, wrong status and invalid lines', () async {
    final before = repo.calls;
    const other = Profile(id: 'other', fullName: 'Other', role: UserRole.admin);
    for (final (candidate, profile, quantities) in [
      (order, staff, {'line': 3}),
      (order, other, {'line': 3}),
      (
        WarehouseOrder(
          id: order.id,
          orderCode: order.orderCode,
          type: order.type,
          status: OrderStatus.cancelled,
          createdBy: owner.id,
          items: order.items,
        ),
        owner,
        {'line': 3},
      ),
      (order, owner, {'line': 0}),
      (order, owner, {'line': -1}),
      (order, owner, {'line': 6}),
      (order, owner, {'wrong': 1}),
    ]) {
      expect(
        (await usecase.confirm(
          candidate,
          profile,
          actualQuantities: quantities,
          idempotencyKey: 'key',
        )).isLeft(),
        isTrue,
      );
    }
    expect(repo.calls, before);
  });
}
