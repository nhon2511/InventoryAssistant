import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:smart_wms/core/widgets/error_widget.dart';
import 'package:smart_wms/core/widgets/loading_widget.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/location_controller.dart';

/// Screen displaying the list of warehouse locations.
class LocationListScreen extends ConsumerWidget {
  const LocationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationsAsync = ref.watch(locationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Vị trí kệ hàng')),
      body: locationsAsync.when(
        loading: () => const AppLoadingWidget(message: 'Đang tải vị trí...'),
        error: (error, _) => AppErrorWidget(
          message: error.toString(),
          onRetry: () => ref.invalidate(locationControllerProvider),
        ),
        data: (locations) => ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final loc = locations[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.location_on_outlined),
                title: Text(loc.displayLabel),
                subtitle: Text('Barcode: ${loc.locationBarcode}'),
                trailing: loc.maxCapacityKg != null
                    ? Text('${loc.maxCapacityKg} kg')
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
