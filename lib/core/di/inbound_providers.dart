import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inbound/data/datasources/inbound_remote_datasource.dart';
import 'package:smart_wms/features/inbound/data/repositories/inbound_repository_impl.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';
import 'package:smart_wms/features/inbound/domain/usecases/add_scanned_item_usecase.dart';
import 'package:smart_wms/features/inbound/domain/usecases/confirm_inbound_order_usecase.dart';
import 'package:smart_wms/features/inbound/domain/usecases/create_inbound_order_usecase.dart';
import 'package:smart_wms/features/inbound/domain/usecases/get_inbound_orders_usecase.dart';

final inboundRemoteDataSourceProvider = Provider<InboundRemoteDataSource>((
  ref,
) {
  return InboundRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final inboundRepositoryProvider = Provider<InboundRepository>((ref) {
  return InboundRepositoryImpl(ref.watch(inboundRemoteDataSourceProvider));
});

final getInboundOrdersUseCaseProvider = Provider<GetInboundOrdersUseCase>((
  ref,
) {
  return GetInboundOrdersUseCase(ref.watch(inboundRepositoryProvider));
});

final createInboundOrderUseCaseProvider = Provider<CreateInboundOrderUseCase>((
  ref,
) {
  return CreateInboundOrderUseCase(ref.watch(inboundRepositoryProvider));
});

final addScannedItemUseCaseProvider = Provider<AddScannedItemUseCase>((ref) {
  return AddScannedItemUseCase(ref.watch(inboundRepositoryProvider));
});

final confirmInboundOrderUseCaseProvider = Provider<ConfirmInboundOrderUseCase>(
  (ref) {
    return ConfirmInboundOrderUseCase(ref.watch(inboundRepositoryProvider));
  },
);
