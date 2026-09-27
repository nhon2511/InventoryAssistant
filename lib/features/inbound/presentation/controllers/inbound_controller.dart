import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/config/app_config.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inbound/data/datasources/inbound_remote_datasource.dart';
import 'package:smart_wms/features/inbound/data/repositories/inbound_repository_impl.dart';
import 'package:smart_wms/features/inbound/data/repositories/mock_inbound_repository.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

part 'inbound_controller.g.dart';

@riverpod
class InboundController extends _$InboundController {
  late InboundRepository _repository;

  @override
  Future<List<WarehouseOrder>> build() async {
    if (AppConfig.useMock) {
      _repository = mockInboundRepository;
    } else {
      final client = ref.watch(supabaseClientProvider);
      _repository = InboundRepositoryImpl(InboundRemoteDataSourceImpl(client));
    }
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

  Future<String> createDraft() async {
    final result = await _repository.createInboundOrder();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (order) {
        ref.invalidateSelf();
        return order.id;
      },
    );
  }

  Future<WarehouseOrder> getById(String id) async {
    final result = await _repository.getInboundOrderById(id);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (order) => order,
    );
  }
}
