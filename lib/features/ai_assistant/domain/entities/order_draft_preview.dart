import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/features/inbound/domain/entities/warehouse_order.dart';

class OrderDraftPreview {
  const OrderDraftPreview({required this.type, required this.items, this.note});
  final OrderType type;
  final List<WarehouseOrderItem> items;
  final String? note;
}
