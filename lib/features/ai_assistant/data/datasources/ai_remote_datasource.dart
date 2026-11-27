import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/errors/exceptions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Remote data source for AI assistant operations via Supabase Edge Functions.
abstract class AiRemoteDataSource {
  Future<Map<String, dynamic>> parseIntent(String userText);
  Future<String> queryStock(Map<String, String> entities);
  Future<Map<String, dynamic>> createDraftOrder(Map<String, String> entities);
}

/// Production guard until Edge Function source, deployment and JWT contract are verified.
class UnavailableAiRemoteDataSource implements AiRemoteDataSource {
  const UnavailableAiRemoteDataSource();

  static const message = 'Trợ lý AI hiện chưa khả dụng. Vui lòng thử lại sau.';

  @override
  Future<Map<String, dynamic>> parseIntent(String userText) =>
      Future.error(const AiException(message: message, statusCode: 503));

  @override
  Future<String> queryStock(Map<String, String> entities) =>
      Future.error(const AiException(message: message, statusCode: 503));

  @override
  Future<Map<String, dynamic>> createDraftOrder(Map<String, String> entities) =>
      Future.error(const AiException(message: message, statusCode: 503));
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

  @override
  Future<Map<String, dynamic>> createDraftOrder(
    Map<String, String> entities,
  ) async {
    try {
      final response = await _client.functions.invoke(
        AppConstants.createDraftOrderFunction,
        body: entities,
      );
      final data = response.data as Map<String, dynamic>;
      return data;
    } on FunctionException catch (e) {
      throw AiException(
        message: e.details?.toString() ?? 'Lỗi tạo phiếu nháp',
        statusCode: e.status,
      );
    }
  }
}
