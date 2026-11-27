import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/features/inventory/data/datasources/nest_stock_datasource.dart';

void main() {
  const baseUrl = 'https://warehouse.example.test';

  test('sends current Supabase token and parses Nest stock envelope', () async {
    var token = 'first';
    final client = MockClient((request) async {
      expect(request.url.toString(), '$baseUrl/api/v1/inventory/stock');
      expect(request.headers['Authorization'], 'Bearer $token');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': [
            {
              'id': 'item',
              'productId': 'product',
              'locationId': 'location',
              'quantityOnHand': 12,
              'quantityReserved': 2,
              'lotNumber': null,
              'expiryDate': null,
              'updatedAt': '2026-11-27T00:00:00.000Z',
            },
          ],
        }),
        200,
      );
    });
    final source = NestStockDataSource(
      NestApiClient(client, () => token, baseUrl: baseUrl),
    );
    final first = await source.getAllInventoryItems();
    expect(first.single.quantityOnHand, 12);
    expect(first.single.quantityReserved, 2);
    token = 'refreshed';
    await source.getAllInventoryItems();
  });

  test('refuses missing token before making request', () async {
    var called = false;
    final client = MockClient((_) async {
      called = true;
      return http.Response('{}', 200);
    });
    final source = NestStockDataSource(
      NestApiClient(client, () => null, baseUrl: baseUrl),
    );
    await expectLater(
      source.getAllInventoryItems(),
      throwsA(
        isA<ServerException>().having((e) => e.statusCode, 'status', 401),
      ),
    );
    expect(called, isFalse);
  });

  for (final (status, message) in [
    (401, 'Phiên đăng nhập'),
    (403, 'không có quyền'),
    (404, 'Không tìm thấy'),
    (422, 'không hợp lệ'),
    (500, 'gặp lỗi'),
  ]) {
    test('maps HTTP $status to friendly failure', () async {
      final source = NestStockDataSource(
        NestApiClient(
          MockClient((_) async => http.Response('{}', status)),
          () => 'token',
          baseUrl: baseUrl,
        ),
      );
      await expectLater(
        source.getAllInventoryItems(),
        throwsA(
          isA<ServerException>()
              .having((e) => e.statusCode, 'status', status)
              .having((e) => e.message, 'message', contains(message)),
        ),
      );
    });
  }

  test('rejects malformed payload', () async {
    final source = NestStockDataSource(
      NestApiClient(
        MockClient(
          (_) async =>
              http.Response('{"success":true,"data":[{"id":"x"}]}', 200),
        ),
        () => 'token',
        baseUrl: baseUrl,
      ),
    );
    await expectLater(
      source.getAllInventoryItems(),
      throwsA(isA<ServerException>()),
    );
  });

  test('maps transport and timeout errors', () async {
    for (final error in <Object>[
      http.ClientException('offline'),
      TimeoutException('slow'),
    ]) {
      final source = NestStockDataSource(
        NestApiClient(
          MockClient((_) async => Future<http.Response>.error(error)),
          () => 'token',
          baseUrl: baseUrl,
        ),
      );
      await expectLater(
        source.getAllInventoryItems(),
        throwsA(isA<ServerException>()),
      );
    }
  });
}
