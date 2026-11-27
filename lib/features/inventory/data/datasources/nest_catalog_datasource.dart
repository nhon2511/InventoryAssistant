import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/features/inventory/data/models/location_model.dart';
import 'package:smart_wms/features/inventory/data/models/product_model.dart';
import 'package:smart_wms/features/inventory/domain/entities/location.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';

class NestCatalogDataSource {
  const NestCatalogDataSource(this.api);
  final NestApiClient api;

  Future<List<ProductModel>> products() async =>
      _list(await api.get('/api/v1/products'), ProductModel.fromNestJson);
  Future<ProductModel> product(String id) async => _one(
    await api.get('/api/v1/products/${Uri.encodeComponent(id)}'),
    ProductModel.fromNestJson,
  );
  Future<List<LocationModel>> locations() async =>
      _list(await api.get('/api/v1/locations'), LocationModel.fromNestJson);
  Future<LocationModel> location(String barcode) async => _one(
    await api.get('/api/v1/locations/${Uri.encodeComponent(barcode)}'),
    LocationModel.fromNestJson,
  );

  Future<ProductModel> saveProduct(Product product) async {
    final body = <String, dynamic>{
      'name': product.name,
      'sku': product.sku,
      'barcode': product.barcode,
      'unit': product.unit,
      'description': product.description,
      'minSafetyStock': product.minSafetyStock,
    };
    return _one(
      product.id.isEmpty
          ? await api.post('/api/v1/products', body)
          : await api.put(
              '/api/v1/products/${Uri.encodeComponent(product.id)}',
              body,
            ),
      ProductModel.fromNestJson,
    );
  }

  Future<LocationModel> saveLocation(Location location) async {
    final body = <String, dynamic>{
      'zoneCode': location.zoneCode,
      'aisleCode': location.aisleCode,
      'rackCode': location.rackCode,
      'binCode': location.binCode,
      'locationBarcode': location.locationBarcode,
      'maxCapacityKg': location.maxCapacityKg,
    };
    return _one(
      location.id.isEmpty
          ? await api.post('/api/v1/locations', body)
          : await api.put(
              '/api/v1/locations/${Uri.encodeComponent(location.id)}',
              body,
            ),
      LocationModel.fromNestJson,
    );
  }

  Future<void> deleteProduct(String id) =>
      api.delete('/api/v1/products/${Uri.encodeComponent(id)}').then((_) {});
  Future<void> deleteLocation(String id) =>
      api.delete('/api/v1/locations/${Uri.encodeComponent(id)}').then((_) {});

  T _one<T>(Object? data, T Function(Map<String, dynamic>) parse) {
    if (data is! Map<String, dynamic>) {
      throw const ServerException(
        message: 'Dữ liệu danh mục từ máy chủ không hợp lệ.',
      );
    }
    try {
      return parse(data);
    } on FormatException {
      throw const ServerException(
        message: 'Dữ liệu danh mục từ máy chủ không hợp lệ.',
      );
    }
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) parse) {
    if (data is! List) {
      throw const ServerException(
        message: 'Danh sách từ máy chủ không hợp lệ.',
      );
    }
    return data.map((item) => _one(item, parse)).toList();
  }
}
