import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:smart_wms/core/constants/app_constants.dart';
import 'package:smart_wms/core/errors/exceptions.dart';

/// Remote data source for AI assistant that calls the NestJS backend.
///
/// Replace `AiRemoteDataSourceImpl` (Supabase Edge Functions) with this
/// when the NestJS /api/v1/ai endpoints are live.
class NestJsAiDataSource {
  const NestJsAiDataSource({required this.accessToken});

  final String accessToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      };

  Uri _uri(String path) =>
      Uri.parse('${AppConstants.nestJsBaseUrl}${AppConstants.nestJsAiPath}$path');

  // ─── 1. Parse Intent ────────────────────────────────────────────────────

  Future<Map<String, dynamic>> parseIntent(String userText) async {
    final res = await http
        .post(
          _uri('/parse-intent'),
          headers: _headers,
          body: jsonEncode({'text': userText}),
        )
        .timeout(AppConstants.requestTimeout);

    _assertOk(res, 'parse-intent');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── 2. Query Stock ──────────────────────────────────────────────────────

  Future<String> queryStock(Map<String, String> entities) async {
    final res = await http
        .post(
          _uri('/query-stock'),
          headers: _headers,
          body: jsonEncode(entities),
        )
        .timeout(AppConstants.requestTimeout);

    _assertOk(res, 'query-stock');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['answer'] as String? ?? 'Không tìm thấy kết quả.';
  }

  // ─── 3. Create Draft Order ───────────────────────────────────────────────

  Future<Map<String, dynamic>> createDraftOrder(
    Map<String, String> entities,
  ) async {
    final res = await http
        .post(
          _uri('/create-draft'),
          headers: _headers,
          body: jsonEncode(entities),
        )
        .timeout(AppConstants.requestTimeout);

    _assertOk(res, 'create-draft');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  void _assertOk(http.Response res, String endpoint) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw AiException(
        message: 'AI $endpoint lỗi ${res.statusCode}: ${res.body}',
        statusCode: res.statusCode,
      );
    }
  }
}
