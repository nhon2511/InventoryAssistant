import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/orders/domain/usecases/apply_order_scan.dart';

void main() {
  const scanner = ApplyOrderScan();
  final now = DateTime(2026, 11, 27);
  const products = [
    Product(
      id: 'p1',
      sku: 'S1',
      barcode: 'ABC',
      name: 'A',
      unit: 'cái',
      minSafetyStock: 0,
    ),
    Product(
      id: 'p2',
      sku: 'S2',
      barcode: 'OTHER',
      name: 'B',
      unit: 'cái',
      minSafetyStock: 0,
    ),
  ];
  const order = WarehouseOrder(
    id: 'o1',
    orderCode: 'O1',
    type: OrderType.inbound,
    status: OrderStatus.confirmed,
    items: [
      WarehouseOrderItem(
        id: 'l1',
        orderId: 'o1',
        productId: 'p1',
        expectedQuantity: 2,
        actualQuantity: 0,
      ),
    ],
  );
  OrderScanResult scan(
    String code, {
    Map<String, int> quantities = const {},
    bool camera = false,
    String? previous,
    DateTime? previousAt,
    WarehouseOrder target = order,
  }) => scanner(
    order: target,
    products: products,
    actualQuantities: quantities,
    barcode: code,
    now: now,
    fromCamera: camera,
    previousCameraBarcode: previous,
    previousCameraAt: previousAt,
  );

  test('matching barcode increments only its line and respects cap', () {
    expect(scan('ABC').quantity, 1);
    expect(scan('ABC', quantities: {'l1': 1}).quantity, 2);
    expect(scan('ABC', quantities: {'l1': 2}).message, contains('mức dự kiến'));
  });
  test(
    'unknown, wrong-order, duplicate and repeated camera frame are rejected',
    () {
      expect(scan('UNKNOWN').accepted, false);
      expect(scan('OTHER').message, contains('không thuộc phiếu'));
      expect(
        scan(
          'ABC',
          camera: true,
          previous: 'ABC',
          previousAt: now.subtract(const Duration(milliseconds: 100)),
        ).accepted,
        false,
      );
      expect(
        scan(
          'ABC',
          camera: true,
          previous: 'ABC',
          previousAt: now.subtract(const Duration(seconds: 2)),
        ).accepted,
        true,
      );
      final duplicate = WarehouseOrder(
        id: 'o1',
        orderCode: 'O1',
        type: OrderType.inbound,
        status: OrderStatus.confirmed,
        items: [
          ...order.items,
          const WarehouseOrderItem(
            id: 'l2',
            orderId: 'o1',
            productId: 'p1',
            expectedQuantity: 1,
            actualQuantity: 0,
          ),
        ],
      );
      expect(scan('ABC', target: duplicate).message, contains('nhiều dòng'));
    },
  );
  test('draft orders cannot be scanned', () {
    const draft = WarehouseOrder(
      id: 'o1',
      orderCode: 'O1',
      type: OrderType.inbound,
      status: OrderStatus.draft,
    );
    expect(scan('ABC', target: draft).accepted, false);
  });
}
