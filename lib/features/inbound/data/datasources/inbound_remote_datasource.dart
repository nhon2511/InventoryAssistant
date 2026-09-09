import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/utils/order_code_generator.dart';
import 'package:smart_wms/features/inbound/data/models/warehouse_order_item_model.dart';
import 'package:smart_wms/features/inbound/data/models/warehouse_order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for inbound warehouse operations.
abstract class InboundRemoteDataSource {
  Future<WarehouseOrderModel> createInboundOrder({String? note});
  Future<WarehouseOrderItemModel> addOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    String? locationId,
    String? lotNumber,
    String? expiryDate,
  });
  Future<WarehouseOrderModel> confirmInbound(String orderId);
  Future<List<WarehouseOrderModel>> getInboundOrders();
  Future<WarehouseOrderModel> getOrderById(String orderId);
  Future<List<WarehouseOrderItemModel>> getOrderItems(String orderId);
}

class InboundRemoteDataSourceImpl implements InboundRemoteDataSource {
  const InboundRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<WarehouseOrderModel> createInboundOrder({String? note}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final orderCode = OrderCodeGenerator.generate(OrderType.inbound, 1);

      final data = await _client
          .from(AppConstants.warehouseOrdersTable)
          .insert({
            'order_code': orderCode,
            'type': OrderType.inbound.dbValue,
            'status': 'DRAFT',
            'created_by': userId,
            'note': note,
          })
          .select()
          .single();
      return WarehouseOrderModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<WarehouseOrderItemModel> addOrderItem({
    required String orderId,
    required String productId,
    required int quantity,
    String? locationId,
    String? lotNumber,
    String? expiryDate,
  }) async {
    try {
      final data = await _client
          .from(AppConstants.warehouseOrderItemsTable)
          .insert({
            'order_id': orderId,
            'product_id': productId,
            'expected_quantity': quantity,
            'actual_quantity': quantity,
            'location_id': locationId,
            'lot_number': lotNumber,
            'expiry_date': expiryDate,
          })
          .select()
          .single();
      return WarehouseOrderItemModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<WarehouseOrderModel> confirmInbound(String orderId) async {
    try {
      final data = await _client
          .from(AppConstants.warehouseOrdersTable)
          .update({'status': 'COMPLETED'})
          .eq('id', orderId)
          .select()
          .single();
      return WarehouseOrderModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<WarehouseOrderModel>> getInboundOrders() async {
    try {
      final data = await _client
          .from(AppConstants.warehouseOrdersTable)
          .select()
          .eq('type', OrderType.inbound.dbValue)
          .order('created_at', ascending: false);
      return data.map(WarehouseOrderModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<WarehouseOrderModel> getOrderById(String orderId) async {
    try {
      final data = await _client
          .from(AppConstants.warehouseOrdersTable)
          .select()
          .eq('id', orderId)
          .single();
      return WarehouseOrderModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<WarehouseOrderItemModel>> getOrderItems(String orderId) async {
    try {
      final data = await _client
          .from(AppConstants.warehouseOrderItemsTable)
          .select()
          .eq('order_id', orderId);
      return data.map(WarehouseOrderItemModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }
}
