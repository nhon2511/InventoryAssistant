import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/orders/domain/repositories/order_workflow_repository.dart';

class NestOrderDataSource {
  const NestOrderDataSource(this.api);
  final NestApiClient api;

  Future<List<WarehouseOrder>> list(OrderType type) async {
    final data = await api.get('/api/v1/orders?type=${type.dbValue}');
    if (data is! List) {
      throw const ServerException(message: 'Danh sách phiếu không hợp lệ.');
    }
    return data.map(_parse).toList();
  }

  Future<WarehouseOrder> detail(String id) async =>
      _parse(await api.get('/api/v1/orders/${Uri.encodeComponent(id)}'));

  Future<WarehouseOrder> saveDraft({
    required OrderType type,
    required List<WarehouseOrderItem> items,
    required String requestId,
    String? note,
  }) async => _parse(
    await api.post('/api/v1/orders/draft', {
      'type': type.dbValue,
      'requestId': requestId,
      'note': note,
      'items': items
          .map(
            (item) => {
              'productId': item.productId,
              'locationId': item.locationId,
              'expectedQuantity': item.expectedQuantity,
              if (item.lotNumber != null) 'lotNumber': item.lotNumber,
              if (item.expiryDate != null)
                'expiryDate': item.expiryDate!.toIso8601String().substring(
                  0,
                  10,
                ),
            },
          )
          .toList(),
    }),
  );

  Future<WarehouseOrder> review(String id, {required bool approve}) async =>
      _parse(
        await api.post('/api/v1/orders/${Uri.encodeComponent(id)}/review', {
          'approve': approve,
        }),
      );

  Future<OrderConfirmationOutcome> confirm({
    required String orderId,
    required OrderType type,
    required Map<String, int> actualQuantities,
    required String idempotencyKey,
  }) async {
    final data = await api.post(
      '/api/v1/orders/${Uri.encodeComponent(orderId)}/confirm',
      {
        'type': type.dbValue,
        'idempotencyKey': idempotencyKey,
        'lines': actualQuantities.entries
            .map(
              (entry) => {'lineId': entry.key, 'actualQuantity': entry.value},
            )
            .toList(),
      },
    );
    if (data is! Map<String, dynamic> ||
        data['orderId'] != orderId ||
        data['movements'] is! int ||
        data['movements'] != actualQuantities.length) {
      throw const ServerException(
        message: 'Kết quả xác nhận từ máy chủ không hợp lệ.',
      );
    }
    return switch (data['kind']) {
      'applied' => OrderConfirmationOutcome.applied,
      'replay' => OrderConfirmationOutcome.replay,
      _ => throw const ServerException(
        message: 'Kết quả xác nhận từ máy chủ không hợp lệ.',
      ),
    };
  }

  WarehouseOrder _parse(Object? data) {
    if (data is! Map<String, dynamic> ||
        data['id'] is! String ||
        data['orderCode'] is! String ||
        data['type'] is! String ||
        data['status'] is! String ||
        data['items'] is! List) {
      throw const ServerException(
        message: 'Dữ liệu phiếu từ máy chủ không hợp lệ.',
      );
    }
    final type = OrderType.values
        .where((v) => v.dbValue == data['type'])
        .firstOrNull;
    final status = OrderStatus.values
        .where((v) => v.dbValue == data['status'])
        .firstOrNull;
    if (type == null || status == null) {
      throw const ServerException(message: 'Trạng thái phiếu không hợp lệ.');
    }
    final items = <WarehouseOrderItem>[];
    for (final raw in data['items'] as List) {
      if (raw is! Map<String, dynamic> ||
          raw['id'] is! String ||
          raw['orderId'] is! String ||
          raw['productId'] is! String ||
          raw['expectedQuantity'] is! int ||
          raw['actualQuantity'] is! int) {
        throw const ServerException(
          message: 'Dòng hàng từ máy chủ không hợp lệ.',
        );
      }
      final product = raw['product'];
      items.add(
        WarehouseOrderItem(
          id: raw['id'] as String,
          orderId: raw['orderId'] as String,
          productId: raw['productId'] as String,
          locationId: _optionalString(raw['locationId']),
          expectedQuantity: raw['expectedQuantity'] as int,
          actualQuantity: raw['actualQuantity'] as int,
          lotNumber: _optionalString(raw['lotNumber']),
          expiryDate: DateTime.tryParse(raw['expiryDate']?.toString() ?? ''),
          productName: product is Map<String, dynamic>
              ? _optionalString(product['name'])
              : null,
        ),
      );
    }
    return WarehouseOrder(
      id: data['id'] as String,
      orderCode: data['orderCode'] as String,
      type: type,
      status: status,
      createdBy: _optionalString(data['createdBy']),
      approvedBy: _optionalString(data['approvedBy']),
      note: _optionalString(data['note']),
      createdAt: DateTime.tryParse(data['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
      items: items,
    );
  }

  String? _optionalString(Object? value) {
    if (value == null || value is String) return value as String?;
    throw const ServerException(
      message: 'Dữ liệu phiếu từ máy chủ không hợp lệ.',
    );
  }
}
