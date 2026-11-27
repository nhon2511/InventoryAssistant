import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/network/nest_api_client.dart';
import 'package:smart_wms/features/inventory/data/models/inventory_item_model.dart';

class NestStockDataSource {
  const NestStockDataSource(this.api);

  final NestApiClient api;

  Future<List<InventoryItemModel>> getAllInventoryItems() async {
    return _parse(await api.get('/api/v1/inventory/stock'));
  }

  Future<List<InventoryItemModel>> getStockByProduct(String productId) async {
    return _parse(
      await api.get(
        '/api/v1/inventory/stock?productId=${Uri.encodeQueryComponent(productId)}',
      ),
    );
  }

  List<InventoryItemModel> _parse(Object? data) {
    try {
      if (data is! List) throw const FormatException();
      return data.map((item) {
        if (item is! Map<String, dynamic>) throw const FormatException();
        return InventoryItemModel.fromNestJson(item);
      }).toList();
    } on FormatException {
      throw const ServerException(
        message: 'Dữ liệu tồn kho từ máy chủ không hợp lệ.',
      );
    }
  }
}
