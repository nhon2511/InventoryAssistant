import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/config/app_config.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inbound/data/datasources/inbound_remote_datasource.dart';
import 'package:smart_wms/features/inbound/data/repositories/inbound_repository_impl.dart';
import 'package:smart_wms/features/inbound/data/repositories/mock_inbound_repository.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';

final inboundRepositoryProvider = Provider<InboundRepository>((ref) {
  if (AppConfig.useMock) return mockInboundRepository;
  return InboundRepositoryImpl(InboundRemoteDataSourceImpl(ref.watch(supabaseClientProvider)));
});
