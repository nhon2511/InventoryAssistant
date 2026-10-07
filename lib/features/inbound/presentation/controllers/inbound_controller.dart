import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/di/inbound_providers.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/usecases/get_inbound_orders_usecase.dart';

part 'inbound_controller.g.dart';

@riverpod
class InboundController extends _$InboundController {
  late final GetInboundOrdersUseCase _getInboundOrders;

  @override
  Future<List<WarehouseOrder>> build() async {
    _getInboundOrders = ref.watch(getInboundOrdersUseCaseProvider);
    return _fetchOrders();
  }

  Future<List<WarehouseOrder>> _fetchOrders() async {
    final result = await _getInboundOrders(const NoParams());
    return result.fold(
      (failure) => throw StateError(failure.message),
      (orders) => orders,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchOrders);
  }
}
