import 'package:smart_wms/core/enums/order_status.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';
import 'package:smart_wms/features/inventory/domain/entities/product.dart';

class OrderScanResult {
  const OrderScanResult({this.lineId, this.quantity, this.message});

  final String? lineId;
  final int? quantity;
  final String? message;

  bool get accepted => lineId != null;
}

/// Changes only the local confirmation form. The order movement remains in CP5.
class ApplyOrderScan {
  const ApplyOrderScan();

  OrderScanResult call({
    required WarehouseOrder order,
    required List<Product> products,
    required Map<String, int> actualQuantities,
    required String barcode,
    required DateTime now,
    String? previousCameraBarcode,
    DateTime? previousCameraAt,
    bool fromCamera = false,
  }) {
    if (order.status != OrderStatus.confirmed) {
      return const OrderScanResult(message: 'Chỉ quét cho phiếu đã duyệt.');
    }
    final code = barcode.trim();
    if (code.isEmpty) {
      return const OrderScanResult(message: 'Nhập mã vạch để đối soát.');
    }
    if (fromCamera &&
        code == previousCameraBarcode &&
        previousCameraAt != null &&
        now.difference(previousCameraAt) < const Duration(milliseconds: 1200)) {
      return const OrderScanResult(
        message: 'Camera vừa đọc mã này; hãy quét lại sau.',
      );
    }
    final matchingProducts = products.where((p) => p.barcode == code).toList();
    if (matchingProducts.isEmpty) {
      return const OrderScanResult(
        message: 'Mã vạch không có trong danh mục sản phẩm.',
      );
    }
    if (matchingProducts.length != 1) {
      return const OrderScanResult(
        message: 'Mã vạch trùng ở nhiều sản phẩm; cần kiểm tra danh mục.',
      );
    }
    final lines = order.items
        .where((line) => line.productId == matchingProducts.single.id)
        .toList();
    if (lines.isEmpty) {
      return const OrderScanResult(message: 'Sản phẩm không thuộc phiếu này.');
    }
    if (lines.length != 1) {
      return const OrderScanResult(
        message: 'Sản phẩm có nhiều dòng trong phiếu; hãy nhập số lượng thủ công theo dòng.',
      );
    }
    final line = lines.single;
    final next = (actualQuantities[line.id] ?? 0) + 1;
    if (next > line.expectedQuantity) {
      return const OrderScanResult(
        message: 'Số lượng quét đã đạt mức dự kiến.',
      );
    }
    return OrderScanResult(lineId: line.id, quantity: next);
  }
}
