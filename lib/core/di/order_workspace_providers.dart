import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/features/orders/data/datasources/nest_order_datasource.dart';
import 'package:smart_wms/features/orders/data/repositories/nest_order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/usecases/order_workspace_usecase.dart';

final orderWorkflowRepositoryProvider = Provider<OrderWorkflowRepository>(
  (ref) => NestOrderWorkflowRepository(
    NestOrderDataSource(ref.watch(nestApiClientProvider)),
  ),
);
final orderWorkspaceProvider = Provider(
  (ref) => OrderWorkspaceUseCase(ref.watch(orderWorkflowRepositoryProvider)),
);
final readOrdersProvider = Provider(
  (ref) => ReadOrdersUseCase(ref.watch(orderWorkflowRepositoryProvider)),
);
