import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

/// In-memory orders for the offline demo. No Supabase connection is required.
final mockInboundRepository = MockInboundRepository();

class MockInboundRepository implements InboundRepository {
  final List<WarehouseOrder> _orders = List.generate(4, (index) => WarehouseOrder(
    id: 'demo-in-${index + 1}',
    orderCode: 'NK-${(index + 1).toString().padLeft(3, '0')}',
    type: OrderType.inbound,
    status: index == 0 ? OrderStatus.draft : OrderStatus.completed,
    createdAt: DateTime.now().subtract(Duration(days: index * 2)),
  ));

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return value;
  }

  @override
  FutureEither<List<WarehouseOrder>> getInboundOrders() async =>
      Right(await _delay(List<WarehouseOrder>.of(_orders)));

  @override
  FutureEither<WarehouseOrder> getInboundOrderById(String orderId) async {
    await _delay(null);
    for (final order in _orders) {
      if (order.id == orderId) return Right(order);
    }
    return const Left(ServerFailure(message: 'Không tìm thấy phiếu nhập.'));
  }

  @override
  FutureEither<WarehouseOrder> createInboundOrder({String? note}) async {
    final id = _orders.length + 1;
    final order = WarehouseOrder(
      id: 'demo-in-$id',
      orderCode: 'NK-${id.toString().padLeft(3, '0')}',
      type: OrderType.inbound,
      status: OrderStatus.draft,
      note: note,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    return Right(await _delay(order));
  }

  @override
  FutureEither<WarehouseOrderItem> addScannedItem({
    required String orderId,
    required String productId,
    required int quantity,
    String? locationId,
    String? lotNumber,
    DateTime? expiryDate,
  }) async {
    await _delay(null);
    if (quantity <= 0) {
      return const Left(ServerFailure(message: 'Số lượng phải lớn hơn 0.'));
    }
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      return const Left(ServerFailure(message: 'Không tìm thấy phiếu nhập.'));
    }
    final original = _orders[index];
    final item = WarehouseOrderItem(
      id: 'demo-in-item-${original.items.length + 1}',
      orderId: orderId,
      productId: productId,
      locationId: locationId,
      lotNumber: lotNumber,
      expiryDate: expiryDate,
      expectedQuantity: quantity,
      actualQuantity: quantity,
    );
    _orders[index] = WarehouseOrder(
      id: original.id,
      orderCode: original.orderCode,
      type: original.type,
      status: original.status,
      note: original.note,
      createdAt: original.createdAt,
      items: [...original.items, item],
    );
    return Right(item);
  }

  @override
  FutureEither<WarehouseOrder> confirmInboundOrder(String orderId) async {
    await _delay(null);
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      return const Left(ServerFailure(message: 'Không tìm thấy phiếu nhập.'));
    }
    final original = _orders[index];
    if (original.items.isEmpty) {
      return const Left(ServerFailure(message: 'Phiếu nhập chưa có sản phẩm.'));
    }
    final confirmed = WarehouseOrder(
      id: original.id,
      orderCode: original.orderCode,
      type: original.type,
      status: OrderStatus.confirmed,
      note: original.note,
      createdAt: original.createdAt,
      items: original.items,
    );
    _orders[index] = confirmed;
    return Right(confirmed);
  }
}
