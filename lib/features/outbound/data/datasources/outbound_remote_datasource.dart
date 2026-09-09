import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/enums/order_type.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/core/utils/order_code_generator.dart';
import 'package:smart_wms/features/inbound/data/models/warehouse_order_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for outbound warehouse operations.
abstract class OutboundRemoteDataSource {
  Future<WarehouseOrderModel> createOutboundOrder({String? note});
  Future<List<WarehouseOrderModel>> getOutboundOrders();
  Future<WarehouseOrderModel> getOrderById(String orderId);
  Future<void> confirmOutbound(String orderId);
}

class OutboundRemoteDataSourceImpl implements OutboundRemoteDataSource {
  const OutboundRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<WarehouseOrderModel> createOutboundOrder({String? note}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      final orderCode = OrderCodeGenerator.generate(OrderType.outbound, 1);

      final data = await _client
          .from(AppConstants.warehouseOrdersTable)
          .insert({
            'order_code': orderCode,
            'type': OrderType.outbound.dbValue,
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
  Future<List<WarehouseOrderModel>> getOutboundOrders() async {
    try {
      final data = await _client
          .from(AppConstants.warehouseOrdersTable)
          .select()
          .eq('type', OrderType.outbound.dbValue)
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
  Future<void> confirmOutbound(String orderId) async {
    try {
      await _client.rpc<void>(
        AppConstants.confirmOutboundOrderRpc,
        params: {'p_order_id': orderId},
      );
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }
}
