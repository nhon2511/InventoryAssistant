import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/orders/data/datasources/nest_order_datasource.dart';
import 'package:smart_wms/features/orders/data/repositories/nest_order_workflow_repository.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';

Map<String, dynamic> envelope(Object? data) => {'success': true, 'data': data};
const requestId = '770e8400-e29b-41d4-a716-446655440099';
final order = <String, dynamic>{
  'id': requestId,
  'orderCode': 'INB-202611-0001',
  'type': 'INBOUND',
  'status': 'DRAFT',
  'createdBy': 'server-user',
  'items': [
    {
      'id': 'line-1',
      'orderId': requestId,
      'productId': 'product-1',
      'locationId': 'location-1',
      'expectedQuantity': 3,
      'actualQuantity': 0,
      'product': {'name': 'Hàng A'},
    },
    {
      'id': 'line-2',
      'orderId': requestId,
      'productId': 'product-2',
      'locationId': 'location-1',
      'expectedQuantity': 5,
      'actualQuantity': 0,
      'product': {'name': 'Hàng B'},
    },
  ],
};

void main() {
  NestOrderWorkflowRepository repository(MockClient client) =>
      NestOrderWorkflowRepository(
        NestOrderDataSource(
          NestApiClient(
            client,
            () => 'jwt-token',
            baseUrl: 'https://api.example.test',
          ),
        ),
      );

  test('creates multi-line draft and retries with stable request ID', () async {
    final bodies = <Map<String, dynamic>>[];
    final repo = repository(
      MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer jwt-token');
        expect(request.url.path, '/api/v1/orders/draft');
        bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
        if (bodies.length == 1) return http.Response('server unavailable', 503);
        return http.Response(jsonEncode(envelope(order)), 201);
      }),
    );
    const items = [
      WarehouseOrderItem(
        id: '',
        orderId: '',
        productId: 'product-1',
        locationId: 'location-1',
        expectedQuantity: 3,
        actualQuantity: 0,
      ),
      WarehouseOrderItem(
        id: '',
        orderId: '',
        productId: 'product-2',
        locationId: 'location-1',
        expectedQuantity: 5,
        actualQuantity: 0,
      ),
    ];
    FutureEither<WarehouseOrder> save() => repo.saveDraft(
      type: OrderType.inbound,
      createdBy: 'untrusted-client-user',
      items: items,
      requestId: requestId,
    );
    expect((await save()).isLeft(), isTrue);
    final retry = await save();
    expect(retry.isRight(), isTrue);
    expect(retry.getRight().toNullable()!.items, hasLength(2));
    expect(bodies, hasLength(2));
    expect(bodies[0]['requestId'], requestId);
    expect(bodies[0]['items'], hasLength(2));
    expect(bodies[0].containsKey('createdBy'), isFalse);
    expect(bodies[0], bodies[1]);
  });

  test(
    'list and detail require real line items, and malformed response fails',
    () async {
      final repo = repository(
        MockClient((request) async {
          final data = request.url.path.endsWith('bad')
              ? {...order, 'items': null}
              : request.url.path.endsWith('orders')
              ? [order]
              : order;
          return http.Response(jsonEncode(envelope(data)), 200);
        }),
      );
      final list = await repo.list(OrderType.inbound);
      expect(list.getRight().toNullable()!.single.items, hasLength(2));
      expect(
        (await repo.detail(requestId)).getRight().toNullable()!.items,
        hasLength(2),
      );
      expect((await repo.detail('bad')).isLeft(), isTrue);
    },
  );

  test(
    'review maps approval and cancellation, rejects stale local state',
    () async {
      final approvals = <bool>[];
      final repo = repository(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer jwt-token');
          approvals.add(
            (jsonDecode(request.body) as Map<String, dynamic>)['approve']
                as bool,
          );
          return http.Response(
            jsonEncode(
              envelope({
                ...order,
                'status': approvals.last ? 'CONFIRMED' : 'CANCELLED',
              }),
            ),
            200,
          );
        }),
      );
      FutureEither<WarehouseOrder> review(
        OrderStatus status, {
        required bool approve,
      }) => repo.review(
        orderId: requestId,
        expectedStatus: status,
        approve: approve,
        reviewerId: 'untrusted-client-reviewer',
      );
      expect(
        (await review(
          OrderStatus.draft,
          approve: true,
        )).getRight().toNullable()!.status,
        OrderStatus.confirmed,
      );
      expect(
        (await review(
          OrderStatus.draft,
          approve: false,
        )).getRight().toNullable()!.status,
        OrderStatus.cancelled,
      );
      expect(
        (await review(OrderStatus.confirmed, approve: true)).isLeft(),
        isTrue,
      );
      expect(approvals, [true, false]);
    },
  );

  for (final status in [401, 403, 404, 400, 409]) {
    test('maps HTTP $status to a failure without fake success', () async {
      final repo = repository(
        MockClient((_) async => http.Response('{}', status)),
      );
      final result = await repo.detail(requestId);
      expect(result.isLeft(), isTrue);
      expect(result.getLeft().toNullable()!.message, isNotEmpty);
    });
  }

  test(
    'confirm sends actual quantities and stable key, accepts applied/replay',
    () async {
      final bodies = <Map<String, dynamic>>[];
      final repo = repository(
        MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer jwt-token');
          expect(request.url.path, '/api/v1/orders/$requestId/confirm');
          bodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          return http.Response(
            jsonEncode(
              envelope({
                'kind': bodies.length == 1 ? 'applied' : 'replay',
                'orderId': requestId,
                'movements': 2,
              }),
            ),
            200,
          );
        }),
      );
      FutureEither<OrderConfirmationOutcome> confirm() => repo.confirm(
        orderId: requestId,
        type: OrderType.inbound,
        actualQuantities: {'line-1': 2, 'line-2': 4},
        idempotencyKey: 'stable-key',
      );
      expect(
        (await confirm()).getRight().toNullable(),
        OrderConfirmationOutcome.applied,
      );
      expect(
        (await confirm()).getRight().toNullable(),
        OrderConfirmationOutcome.replay,
      );
      expect(bodies[0], bodies[1]);
      expect(bodies[0]['lines'], [
        {'lineId': 'line-1', 'actualQuantity': 2},
        {'lineId': 'line-2', 'actualQuantity': 4},
      ]);
      expect(bodies[0]['idempotencyKey'], 'stable-key');
    },
  );

  test('confirm rejects malformed success and HTTP conflicts', () async {
    final malformed = repository(
      MockClient(
        (_) async => http.Response(
          jsonEncode(
            envelope({'kind': 'applied', 'orderId': requestId, 'movements': 0}),
          ),
          200,
        ),
      ),
    );
    final conflict = repository(
      MockClient((_) async => http.Response('{}', 409)),
    );
    for (final repo in [malformed, conflict]) {
      final result = await repo.confirm(
        orderId: requestId,
        type: OrderType.outbound,
        actualQuantities: {'line-1': 1},
        idempotencyKey: 'stable-key',
      );
      expect(result.isLeft(), isTrue);
    }
  });
}
