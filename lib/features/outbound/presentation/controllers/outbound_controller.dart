import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/config/app_config.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/data/datasources/outbound_remote_datasource.dart';
import 'package:smart_wms/features/outbound/data/repositories/outbound_repository_impl.dart';
import 'package:smart_wms/features/outbound/data/repositories/mock_outbound_repository.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

part 'outbound_controller.g.dart';

@riverpod
class OutboundController extends _$OutboundController {
  late OutboundRepository _repository;

  @override
  Future<List<WarehouseOrder>> build() async {
    if (AppConfig.useMock) {
      _repository = mockOutboundRepository;
    } else {
      final client = ref.watch(supabaseClientProvider);
      _repository = OutboundRepositoryImpl(OutboundRemoteDataSourceImpl(client));
    }
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

  Future<String> createDraft() async {
    final result = await _repository.createOutboundOrder();
    return result.fold(
      (failure) => throw Exception(failure.message),
      (order) {
        ref.invalidateSelf();
        return order.id;
      },
    );
  }

  Future<WarehouseOrder> getById(String id) async {
    final result = await _repository.getOutboundOrderById(id);
    return result.fold(
      (failure) => throw Exception(failure.message),
      (order) => order,
    );
  }
}
