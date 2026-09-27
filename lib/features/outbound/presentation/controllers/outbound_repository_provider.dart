import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/config/app_config.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/outbound/data/datasources/outbound_remote_datasource.dart';
import 'package:smart_wms/features/outbound/data/repositories/outbound_repository_impl.dart';
import 'package:smart_wms/features/outbound/data/repositories/mock_outbound_repository.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';

final outboundRepositoryProvider = Provider<OutboundRepository>((ref) {
  if (AppConfig.useMock) return mockOutboundRepository;
  return OutboundRepositoryImpl(OutboundRemoteDataSourceImpl(ref.watch(supabaseClientProvider)));
});
