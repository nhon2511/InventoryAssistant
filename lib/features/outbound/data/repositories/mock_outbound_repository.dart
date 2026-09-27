import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

/// In-memory outbound orders for the offline UI demo.
final mockOutboundRepository = MockOutboundRepository();

class MockOutboundRepository implements OutboundRepository {
  final List<WarehouseOrder> _orders = List.generate(3, (index) => WarehouseOrder(
    id: 'demo-out-${index + 1}',
    orderCode: 'XK-${(index + 1).toString().padLeft(3, '0')}',
    type: OrderType.outbound,
    status: index == 0 ? OrderStatus.draft : OrderStatus.completed,
    createdAt: DateTime.now().subtract(Duration(days: index * 2 + 1)),
  ));

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return value;
  }

  @override
  FutureEither<List<WarehouseOrder>> getOutboundOrders() async =>
      Right(await _delay(List<WarehouseOrder>.of(_orders)));

  @override
  FutureEither<WarehouseOrder> getOutboundOrderById(String orderId) async {
    await _delay(null);
    for (final order in _orders) {
      if (order.id == orderId) return Right(order);
    }
    return const Left(ServerFailure(message: 'Không tìm thấy phiếu xuất.'));
  }

  @override
  FutureEither<WarehouseOrder> createOutboundOrder({String? note}) async {
    final id = _orders.length + 1;
    final order = WarehouseOrder(
      id: 'demo-out-$id',
      orderCode: 'XK-${id.toString().padLeft(3, '0')}',
      type: OrderType.outbound,
      status: OrderStatus.draft,
      note: note,
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    return Right(await _delay(order));
  }

  @override
  FutureEither<void> confirmOutboundOrder(String orderId) async {
    await _delay(null);
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index < 0) {
      return const Left(ServerFailure(message: 'Không tìm thấy phiếu xuất.'));
    }
    return const Left(ServerFailure(
      message: 'Bản demo chưa có mặt hàng để xác nhận xuất kho.',
    ));
  }
}
