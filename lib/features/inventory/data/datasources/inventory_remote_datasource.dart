import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:smart_wms/features/inventory/data/models/inventory_item_model.dart';
import 'package:smart_wms/features/inventory/data/models/location_model.dart';
import 'package:smart_wms/features/inventory/data/models/product_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for inventory CRUD + Realtime via Supabase.
abstract class InventoryRemoteDataSource {
  Future<List<ProductModel>> getAllProducts();
  Future<ProductModel> getProductByBarcode(String barcode);
  Future<ProductModel> getProductById(String id);
  Future<List<LocationModel>> getAllLocations();
  Future<LocationModel> getLocationByBarcode(String barcode);
  Future<List<InventoryItemModel>> getStockByProduct(String productId);
  Future<List<InventoryItemModel>> getAllInventoryItems();
  Stream<List<InventoryItemModel>> subscribeInventoryRealtime();
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  const InventoryRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final data = await _client
          .from(AppConstants.productsTable)
          .select()
          .order('name');
      return data.map(ProductModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<ProductModel> getProductByBarcode(String barcode) async {
    try {
      final data = await _client
          .from(AppConstants.productsTable)
          .select()
          .eq('barcode', barcode)
          .single();
      return ProductModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<ProductModel> getProductById(String id) async {
    try {
      final data = await _client
          .from(AppConstants.productsTable)
          .select()
          .eq('id', id)
          .single();
      return ProductModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<LocationModel>> getAllLocations() async {
    try {
      final data = await _client
          .from(AppConstants.locationsTable)
          .select()
          .order('location_barcode');
      return data.map(LocationModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<LocationModel> getLocationByBarcode(String barcode) async {
    try {
      final data = await _client
          .from(AppConstants.locationsTable)
          .select()
          .eq('location_barcode', barcode)
          .single();
      return LocationModel.fromJson(data);
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<InventoryItemModel>> getStockByProduct(
    String productId,
  ) async {
    try {
      final data = await _client
          .from(AppConstants.inventoryItemsTable)
          .select()
          .eq('product_id', productId);
      return data.map(InventoryItemModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Future<List<InventoryItemModel>> getAllInventoryItems() async {
    try {
      final data = await _client
          .from(AppConstants.inventoryItemsTable)
          .select();
      return data.map(InventoryItemModel.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(message: e.message);
    }
  }

  @override
  Stream<List<InventoryItemModel>> subscribeInventoryRealtime() {
    return _client
        .from(AppConstants.inventoryItemsTable)
        .stream(primaryKey: ['id']).map(
      (data) => data.map(InventoryItemModel.fromJson).toList(),
    );
  }
}
