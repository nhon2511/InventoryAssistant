import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_wms/core/enums/user_role.dart';
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_catalog_datasource.dart';
import 'package:smart_wms/features/inventory/data/repositories/nest_inventory_maintenance_repository.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/usecases/maintain_inventory_usecase.dart';

Map<String, dynamic> envelope(Object? data) => {'success': true, 'data': data};
final productJson = <String, dynamic>{
  'id': 'p1',
  'sku': 'SKU-1',
  'barcode': '123',
  'name': 'Hàng',
  'unit': 'Cái',
  'minSafetyStock': 2,
  'createdAt': '2026-11-27T00:00:00Z',
  'updatedAt': '2026-11-27T00:00:00Z',
};
final locationJson = <String, dynamic>{
  'id': 'l1',
  'zoneCode': 'A',
  'aisleCode': '1',
  'rackCode': '2',
  'binCode': '3',
  'locationBarcode': 'LOC-1',
  'maxCapacityKg': '12.5',
  'createdAt': '2026-11-27T00:00:00Z',
};
const newProduct = Product(
  id: '',
  sku: 'SKU-1',
  barcode: '123',
  name: 'Hàng',
  unit: 'Cái',
  minSafetyStock: 2,
);
const newLocation = Location(
  id: '',
  zoneCode: 'A',
  aisleCode: '1',
  rackCode: '2',
  binCode: '3',
  locationBarcode: 'LOC-1',
  maxCapacityKg: 12.5,
);

void main() {
  NestCatalogDataSource source(MockClient client) => NestCatalogDataSource(
    NestApiClient(
      client,
      () => 'session-token',
      baseUrl: 'https://api.example.test',
    ),
  );

  test('reads lists and barcode detail from Nest envelope', () async {
    final api = source(
      MockClient((request) async {
        expect(request.headers['Authorization'], 'Bearer session-token');
        final data = switch (request.url.path) {
          '/api/v1/products' => [productJson],
          '/api/v1/products/123' => productJson,
          '/api/v1/locations' => [locationJson],
          '/api/v1/locations/LOC-1' => locationJson,
          _ => throw StateError('unexpected path'),
        };
        return http.Response(jsonEncode(envelope(data)), 200);
      }),
    );
    expect((await api.products()).single.minSafetyStock, 2);
    expect((await api.product('123')).barcode, '123');
    expect((await api.locations()).single.maxCapacityKg, 12.5);
    expect((await api.location('LOC-1')).locationBarcode, 'LOC-1');
  });

  test('creates, updates and deletes with correct method and body', () async {
    final calls = <String>[];
    final api = source(
      MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        if (request.method == 'DELETE') return http.Response('', 204);
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        if (request.url.path.contains('products')) {
          expect(body['minSafetyStock'], 2);
          return http.Response(
            jsonEncode(envelope(productJson)),
            request.method == 'POST' ? 201 : 200,
          );
        }
        expect(body['maxCapacityKg'], request.method == 'POST' ? 12.5 : null);
        return http.Response(
          jsonEncode(envelope(locationJson)),
          request.method == 'POST' ? 201 : 200,
        );
      }),
    );
    expect((await api.saveProduct(newProduct)).id, 'p1');
    await api.saveProduct(
      const Product(
        id: 'p1',
        sku: 'SKU-1',
        barcode: '123',
        name: 'Hàng',
        unit: 'Cái',
        minSafetyStock: 2,
      ),
    );
    expect((await api.saveLocation(newLocation)).id, 'l1');
    await api.saveLocation(
      const Location(
        id: 'l1',
        zoneCode: 'A',
        aisleCode: '1',
        rackCode: '2',
        binCode: '3',
        locationBarcode: 'LOC-1',
      ),
    );
    await api.deleteProduct('p1');
    await api.deleteLocation('l1');
    expect(calls, [
      'POST /api/v1/products',
      'PUT /api/v1/products/p1',
      'POST /api/v1/locations',
      'PUT /api/v1/locations/l1',
      'DELETE /api/v1/products/p1',
      'DELETE /api/v1/locations/l1',
    ]);
  });

  test(
    'maps duplicate, referenced delete and denied requests to Failure',
    () async {
      for (final (status, detail, expected) in [
        (409, 'Product with duplicate sku already exists', 'SKU đã tồn tại'),
        (409, 'inventory items still reference it', 'tham chiếu'),
        (401, 'Unauthorized', 'Phiên đăng nhập'),
        (403, 'Forbidden', 'không có quyền'),
      ]) {
        final repo = NestInventoryMaintenanceRepository(
          source(
            MockClient(
              (_) async => http.Response(
                jsonEncode({'success': false, 'message': detail}),
                status,
              ),
            ),
          ),
        );
        final result = status == 409 && detail.contains('reference')
            ? await repo.deleteProduct('p1')
            : await repo.saveProduct(newProduct);
        expect(result.fold((f) => f.message, (_) => ''), contains(expected));
      }
    },
  );

  test('rejects invalid response without reporting success', () async {
    final repo = NestInventoryMaintenanceRepository(
      source(
        MockClient(
          (_) async => http.Response(
            jsonEncode(
              envelope([
                {'id': 'bad'},
              ]),
            ),
            201,
          ),
        ),
      ),
    );
    final result = await repo.saveProduct(newProduct);
    expect(result.isLeft(), isTrue);
  });

  test(
    'domain allows manager save but blocks staff and manager delete',
    () async {
      final repo = NestInventoryMaintenanceRepository(
        source(
          MockClient(
            (_) async => http.Response(jsonEncode(envelope(productJson)), 201),
          ),
        ),
      );
      final usecase = MaintainInventoryUseCase(repo);
      expect(
        (await usecase.saveProduct(newProduct, UserRole.manager)).isRight(),
        isTrue,
      );
      expect(
        (await usecase.saveProduct(newProduct, UserRole.staff)).isLeft(),
        isTrue,
      );
      expect(
        (await usecase.deleteProduct('p1', UserRole.manager)).isLeft(),
        isTrue,
      );
    },
  );
}
