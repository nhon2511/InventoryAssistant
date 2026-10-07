import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inbound/domain/repositories/inbound_repository.dart';
import 'package:smart_wms/features/inbound/domain/usecases/get_inbound_orders_usecase.dart';

class _MockInboundRepository extends Mock implements InboundRepository {}

void main() {
  late _MockInboundRepository repository;
  late GetInboundOrdersUseCase useCase;

  setUp(() {
    repository = _MockInboundRepository();
    useCase = GetInboundOrdersUseCase(repository);
  });

  test('returns inbound orders from the repository', () async {
    when(
      () => repository.getInboundOrders(),
    ).thenAnswer((_) async => const Right<Failure, List<WarehouseOrder>>([]));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, List<WarehouseOrder>>([]));
    verify(() => repository.getInboundOrders()).called(1);
  });
}
