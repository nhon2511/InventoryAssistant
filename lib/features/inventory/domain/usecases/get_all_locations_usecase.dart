import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Retrieves all warehouse locations.
class GetAllLocationsUseCase extends UseCase<List<Location>, NoParams> {
  const GetAllLocationsUseCase(this._repository);

  final InventoryRepository _repository;

  @override
  FutureEither<List<Location>> call(NoParams params) {
    return _repository.getAllLocations();
  }
}
