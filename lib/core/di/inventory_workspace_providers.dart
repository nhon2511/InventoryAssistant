import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/features/inventory/data/repositories/pending_inventory_maintenance_repository.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_maintenance_repository.dart';
import 'package:smart_wms/features/inventory/domain/usecases/maintain_inventory_usecase.dart';
import 'package:smart_wms/features/inventory/domain/usecases/read_inventory_usecase.dart';

final inventoryMaintenanceRepositoryProvider =
    Provider<InventoryMaintenanceRepository>(
      (ref) => const PendingInventoryMaintenanceRepository(),
    );
final maintainInventoryProvider = Provider(
  (ref) => MaintainInventoryUseCase(
    ref.watch(inventoryMaintenanceRepositoryProvider),
  ),
);
final readInventoryProvider = Provider(
  (ref) => ReadInventoryUseCase(ref.watch(inventoryRepositoryProvider)),
);
