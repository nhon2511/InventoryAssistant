import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/core/usecases/usecase.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/outbound/domain/repositories/outbound_repository.dart';
import 'package:smart_wms/features/outbound/domain/usecases/get_outbound_orders_usecase.dart';

class _MockOutboundRepository extends Mock implements OutboundRepository {}

void main() {
  late _MockOutboundRepository repository;
  late GetOutboundOrdersUseCase useCase;

  setUp(() {
    repository = _MockOutboundRepository();
    useCase = GetOutboundOrdersUseCase(repository);
  });

  test('returns outbound orders from the repository', () async {
    when(
      () => repository.getOutboundOrders(),
    ).thenAnswer((_) async => const Right<Failure, List<WarehouseOrder>>([]));

    final result = await useCase(const NoParams());

    expect(result, const Right<Failure, List<WarehouseOrder>>([]));
    verify(() => repository.getOutboundOrders()).called(1);
  });
}
