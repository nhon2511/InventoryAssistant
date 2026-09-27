import 'package:fpdart/fpdart.dart';
import 'package:smart_wms/core/utils/typedefs.dart';
import 'package:smart_wms/core/errors/failures.dart';
import 'package:smart_wms/features/inventory/domain/entities/inventory_item.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';
import 'package:smart_wms/features/inventory/domain/repositories/inventory_repository.dart';

/// Shared demo data; widgets only see the repository contract.
final mockInventoryRepository = MockInventoryRepository();

class MockInventoryRepository implements InventoryRepository {
  MockInventoryRepository();

  final products = List<Product>.generate(20, (index) => Product(
        id: 'demo-${index + 1}',
        sku: 'SKU-${(index + 1).toString().padLeft(3, '0')}',
        barcode: '893000000${(index + 1).toString().padLeft(4, '0')}',
        name: index == 0 ? 'Mì Hảo Hảo' : 'Sản phẩm ${index + 1}',
        unit: index == 0 ? 'Thùng' : 'Hộp',
        minSafetyStock: 10,
      ));

  late final items = List<InventoryItem>.generate(20, (index) {
    final quantity = index % 7 == 0 ? 0 : index % 4 == 0 ? 5 : 30 + index;
    return InventoryItem(
      id: 'stock-${index + 1}',
      productId: products[index].id,
      productName: products[index].name,
      locationId: 'location-1',
      locationLabel: 'A-01-01-01',
      quantityOnHand: quantity,
      quantityReserved: 0,
      lotNumber: 'LOT-${index + 1}',
      expiryDate: DateTime.now().add(Duration(days: index % 5 == 0 ? 15 : 120)),
    );
  });

  final locations = const [
    Location(id: 'location-1', zoneCode: 'A', aisleCode: '01',
      rackCode: '01', binCode: '01', locationBarcode: 'LOC-A-01'),
  ];

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return value;
  }

  @override
  FutureEither<List<Product>> getAllProducts() async => Right(await _delay(products));

  @override
  FutureEither<Product> getProductByBarcode(String barcode) async {
    await _delay(null);
    for (final product in products) {
      if (product.barcode == barcode) return Right(product);
    }
    return Left(ServerFailure(message: 'Không tìm thấy mã vạch.'));
  }

  @override
  FutureEither<Product> getProductById(String id) async {
    await _delay(null);
    for (final product in products) {
      if (product.id == id) return Right(product);
    }
    return Left(ServerFailure(message: 'Không tìm thấy sản phẩm.'));
  }

  @override
  FutureEither<List<Location>> getAllLocations() async => Right(await _delay(locations));

  @override
  FutureEither<Location> getLocationByBarcode(String barcode) async {
    await _delay(null);
    for (final location in locations) {
      if (location.locationBarcode == barcode) return Right(location);
    }
    return Left(ServerFailure(message: 'Không tìm thấy vị trí.'));
  }

  @override
  FutureEither<List<InventoryItem>> getStockByProduct(String productId) async =>
      Right(await _delay(items.where((item) => item.productId == productId).toList()));

  @override
  FutureEither<List<InventoryItem>> getAllInventoryItems() async =>
      Right(await _delay(items));

  @override
  Stream<List<InventoryItem>> subscribeInventoryRealtime() async* {
    yield await _delay(items);
  }
}
