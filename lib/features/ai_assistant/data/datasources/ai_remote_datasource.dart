import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for AI assistant operations via Supabase Edge Functions.
abstract class AiRemoteDataSource {
  Future<Map<String, dynamic>> parseIntent(String userText);
  Future<String> queryStock(Map<String, String> entities);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  const AiRemoteDataSourceImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> parseIntent(String userText) async {
    try {
      final response = await _client.functions.invoke(
        AppConstants.parseIntentFunction,
        body: {'text': userText},
      );
      final data = response.data as Map<String, dynamic>;
      return data;
    } on FunctionException catch (e) {
      throw AiException(
        message: e.details?.toString() ?? 'Lỗi phân tích ý định',
        statusCode: e.status,
      );
    }
  }

  @override
  Future<String> queryStock(Map<String, String> entities) async {
    try {
      final response = await _client.functions.invoke(
        AppConstants.queryStockFunction,
        body: entities,
      );
      final data = response.data as Map<String, dynamic>;
      return data['answer'] as String? ?? 'Không tìm thấy kết quả.';
    } on FunctionException catch (e) {
      throw AiException(
        message: e.details?.toString() ?? 'Lỗi truy vấn tồn kho',
        statusCode: e.status,
      );
    }
  }
}
