import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/core/di/inbound_providers.dart';
import 'package:smart_wms/core/di/outbound_providers.dart';
import 'package:smart_wms/features/orders/data/repositories/pending_order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/usecases/order_workspace_usecase.dart';

final orderWorkflowRepositoryProvider = Provider<OrderWorkflowRepository>(
  (ref) => const PendingOrderWorkflowRepository(),
);
final orderWorkspaceProvider = Provider(
  (ref) => OrderWorkspaceUseCase(ref.watch(orderWorkflowRepositoryProvider)),
);
final readOrdersProvider = Provider(
  (ref) => ReadOrdersUseCase(
    ref.watch(inboundRepositoryProvider),
    ref.watch(outboundRepositoryProvider),
  ),
);
