import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:smart_wms/core/errors/exceptions.dart';

typedef AccessTokenReader = String? Function();

class NestApiClient {
  NestApiClient(this.client, this.readAccessToken, {String? baseUrl})
    : baseUrl = baseUrl ?? const String.fromEnvironment('NESTJS_BASE_URL');

  final http.Client client;
  final AccessTokenReader readAccessToken;
  final String baseUrl;

  Future<Object?> get(String path) => request('GET', path);
  Future<Object?> post(String path, Map<String, dynamic> body) =>
      request('POST', path, body: body);
  Future<Object?> put(String path, Map<String, dynamic> body) =>
      request('PUT', path, body: body);
  Future<Object?> delete(String path) => request('DELETE', path);

  Future<Object?> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.tryParse(baseUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        (!kDebugMode && uri.scheme != 'https')) {
      throw const ServerException(
        message: 'Chưa cấu hình địa chỉ máy chủ kho hợp lệ.',
      );
    }
    final token = readAccessToken();
    if (token == null || token.isEmpty) {
      throw const ServerException(
        message: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
        statusCode: 401,
      );
    }
    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
      };
      final target = uri.resolve(path);
      final operation = switch (method) {
        'GET' => client.get(target, headers: headers),
        'POST' => client.post(target, headers: headers, body: jsonEncode(body)),
        'PUT' => client.put(target, headers: headers, body: jsonEncode(body)),
        'DELETE' => client.delete(target, headers: headers),
        _ => throw const FormatException('Unsupported method'),
      };
      final response = await operation.timeout(const Duration(seconds: 15));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final detail = _errorDetail(response.body);
        throw ServerException(
          message: switch (response.statusCode) {
            401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            403 => 'Bạn không có quyền thực hiện thao tác này.',
            404 => 'Không tìm thấy dữ liệu yêu cầu.',
            409 when detail.contains('duplicate') && detail.contains('sku') =>
              'SKU đã tồn tại.',
            409
                when detail.contains('duplicate') &&
                    detail.contains('barcode') =>
              'Mã vạch đã tồn tại.',
            409 when detail.contains('reference') =>
              'Không thể xóa vì dữ liệu đang có tồn kho hoặc phiếu tham chiếu.',
            409 => 'Dữ liệu đã thay đổi hoặc bị trùng. Vui lòng kiểm tra lại.',
            400 || 422 =>
              'Dữ liệu gửi lên không hợp lệ. Vui lòng kiểm tra các trường.',
            _ => 'Máy chủ kho đang gặp lỗi. Vui lòng thử lại.',
          },
          statusCode: response.statusCode,
        );
      }
      if (response.statusCode == 204) return null;
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic> ||
          decoded['success'] != true ||
          !decoded.containsKey('data')) {
        throw const FormatException('Invalid API envelope');
      }
      return decoded['data'];
    } on ServerException {
      rethrow;
    } on TimeoutException {
      throw const ServerException(
        message: 'Kết nối máy chủ kho quá thời gian. Vui lòng thử lại.',
      );
    } on http.ClientException {
      throw const ServerException(
        message:
            'Không thể kết nối máy chủ kho. Kiểm tra mạng và địa chỉ máy chủ.',
      );
    } on FormatException {
      throw const ServerException(
        message: 'Dữ liệu từ máy chủ kho không hợp lệ.',
      );
    }
  }

  String _errorDetail(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['message'].toString().toLowerCase();
      }
    } on FormatException {
      // A malformed error body still maps by HTTP status.
    }
    return '';
  }
}
