import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/di/outbound_providers.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/domain/usecases/get_outbound_orders_usecase.dart';

part 'outbound_controller.g.dart';

@riverpod
class OutboundController extends _$OutboundController {
  late final GetOutboundOrdersUseCase _getOutboundOrders;

  @override
  Future<List<WarehouseOrder>> build() async {
    _getOutboundOrders = ref.watch(getOutboundOrdersUseCaseProvider);
    return _fetchOrders();
  }

  Future<List<WarehouseOrder>> _fetchOrders() async {
    final result = await _getOutboundOrders(const NoParams());
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
