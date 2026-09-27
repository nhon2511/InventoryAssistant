import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/config/app_config.dart';
import 'package:smart_wms/core/network/supabase_client_provider.dart';
import 'package:smart_wms/features/inventory/data/datasources/inventory_remote_datasource.dart';
import 'package:smart_wms/features/inventory/data/repositories/inventory_repository_impl.dart';
import 'package:smart_wms/features/inventory/data/repositories/mock_inventory_repository.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  if (AppConfig.useMock) return mockInventoryRepository;
  final client = ref.watch(supabaseClientProvider);
  return InventoryRepositoryImpl(InventoryRemoteDataSourceImpl(client));
});
