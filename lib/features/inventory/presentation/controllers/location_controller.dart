import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inventory/presentation/controllers/inventory_repository_provider.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/usecases/get_all_locations_usecase.dart';

part 'location_controller.g.dart';

@riverpod
class LocationController extends _$LocationController {
  late final GetAllLocationsUseCase _getAllLocations;

  @override
  Future<List<Location>> build() async {
    final repo = ref.watch(inventoryRepositoryProvider);
    _getAllLocations = GetAllLocationsUseCase(repo);

    return _fetchLocations();
  }

  Future<List<Location>> _fetchLocations() async {
    final result = await _getAllLocations(const NoParams());
    return result.fold(
      (failure) => throw Exception(failure.message),
      (locations) => locations,
    );
  }
}
