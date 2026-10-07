import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/outbound/data/datasources/outbound_remote_datasource.dart';
import 'package:smart_wms/features/outbound/data/repositories/outbound_repository_impl.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';
import 'package:smart_wms/features/outbound/domain/usecases/confirm_outbound_order_usecase.dart';
import 'package:smart_wms/features/outbound/domain/usecases/create_outbound_order_usecase.dart';
import 'package:smart_wms/features/outbound/domain/usecases/get_outbound_orders_usecase.dart';

final outboundRemoteDataSourceProvider = Provider<OutboundRemoteDataSource>((
  ref,
) {
  return OutboundRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final outboundRepositoryProvider = Provider<OutboundRepository>((ref) {
  return OutboundRepositoryImpl(ref.watch(outboundRemoteDataSourceProvider));
});

final getOutboundOrdersUseCaseProvider = Provider<GetOutboundOrdersUseCase>((
  ref,
) {
  return GetOutboundOrdersUseCase(ref.watch(outboundRepositoryProvider));
});

final createOutboundOrderUseCaseProvider = Provider<CreateOutboundOrderUseCase>(
  (ref) {
    return CreateOutboundOrderUseCase(ref.watch(outboundRepositoryProvider));
  },
);

final confirmOutboundOrderUseCaseProvider =
    Provider<ConfirmOutboundOrderUseCase>((ref) {
      return ConfirmOutboundOrderUseCase(ref.watch(outboundRepositoryProvider));
    });
