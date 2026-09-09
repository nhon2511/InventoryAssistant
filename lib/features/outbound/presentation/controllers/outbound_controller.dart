import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/data/datasources/outbound_remote_datasource.dart';
import 'package:smart_wms/features/outbound/data/repositories/outbound_repository_impl.dart';

part 'outbound_controller.g.dart';

@riverpod
class OutboundController extends _$OutboundController {
  late final OutboundRepositoryImpl _repository;

  @override
  Future<List<WarehouseOrder>> build() async {
    final client = ref.watch(supabaseClientProvider);
    final ds = OutboundRemoteDataSourceImpl(client);
    _repository = OutboundRepositoryImpl(ds);
    return _fetchOrders();
  }

  Future<List<WarehouseOrder>> _fetchOrders() async {
    final result = await _repository.getOutboundOrders();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (orders) => orders,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchOrders);
  }
}
