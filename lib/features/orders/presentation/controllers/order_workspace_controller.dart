import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/order_workspace_providers.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/auth/presentation/controllers/auth_controller.dart';
import 'package:smart_wms/features/auth/presentation/states/auth_state.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

export 'package:smart_wms/core/di/order_workspace_providers.dart';

final ordersProvider = FutureProvider.family<List<WarehouseOrder>, OrderType>((
  ref,
  type,
) async {
  final auth = ref.watch(authControllerProvider);
  if (auth is! AuthAuthenticated) return [];
  final result = await ref.watch(readOrdersProvider).list(type, auth.profile);
  return result.fold((f) => throw StateError(f.message), (orders) => orders);
});
final orderDetailProvider =
    FutureProvider.family<WarehouseOrder, (OrderType, String)>((
      ref,
      key,
    ) async {
      final auth = ref.watch(authControllerProvider);
      if (auth is! AuthAuthenticated) throw StateError('Chưa đăng nhập.');
      final result = await ref
          .watch(readOrdersProvider)
          .detail(key.$1, key.$2, auth.profile);
      return result.fold((f) => throw StateError(f.message), (order) => order);
    });
