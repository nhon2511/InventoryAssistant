import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wms/app/app.dart';
import 'package:smart_wms/core/di/ai_assistant_providers.dart';
import 'package:smart_wms/core/di/auth_providers.dart';
import 'package:smart_wms/core/di/inbound_providers.dart';
import 'package:smart_wms/core/di/inventory_providers.dart';
import 'package:smart_wms/core/di/outbound_providers.dart';
import 'package:smart_wms/core/di/reports_providers.dart';
import 'package:smart_wms/core/preview/preview_ai_repository.dart';
import 'package:smart_wms/core/preview/preview_mode.dart';
import 'package:smart_wms/core/preview/preview_repository.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_workspace_controller.dart';
import 'package:smart_wms/features/orders/presentation/controllers/order_workspace_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = PreviewRepository(showcase: true);
  runApp(
    ProviderScope(
      overrides: [
        frontendPreviewProvider.overrideWithValue(true),
        aiAssistantRepositoryProvider.overrideWithValue(
          PreviewAiRepository(repository),
        ),
        authRepositoryProvider.overrideWithValue(repository),
        inventoryRepositoryProvider.overrideWithValue(repository),
        inboundRepositoryProvider.overrideWithValue(repository),
        outboundRepositoryProvider.overrideWithValue(repository),
        reportsRepositoryProvider.overrideWithValue(repository),
        inventoryMaintenanceRepositoryProvider.overrideWithValue(repository),
        orderWorkflowRepositoryProvider.overrideWithValue(repository),
      ],
      child: const App(),
    ),
  );
}
