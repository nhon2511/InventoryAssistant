import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inbound/data/datasources/inbound_remote_datasource.dart';
import 'package:smart_wms/features/inbound/data/repositories/inbound_repository_impl.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

part 'inbound_controller.g.dart';

@riverpod
class InboundController extends _$InboundController {
  late final InboundRepositoryImpl _repository;

  @override
  Future<List<WarehouseOrder>> build() async {
    final client = ref.watch(supabaseClientProvider);
    final ds = InboundRemoteDataSourceImpl(client);
    _repository = InboundRepositoryImpl(ds);
    return _fetchOrders();
  }

  Future<List<WarehouseOrder>> _fetchOrders() async {
    final result = await _repository.getInboundOrders();
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
