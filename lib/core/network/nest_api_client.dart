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

  Future<Object?> get(String path) async {
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
      final response = await client
          .get(
            uri.resolve(path),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw ServerException(
          message: switch (response.statusCode) {
            401 => 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
            403 => 'Bạn không có quyền xem dữ liệu tồn kho.',
            404 => 'Không tìm thấy dữ liệu tồn kho.',
            400 || 422 => 'Yêu cầu tra cứu tồn kho không hợp lệ.',
            _ => 'Máy chủ kho đang gặp lỗi. Vui lòng thử lại.',
          },
          statusCode: response.statusCode,
        );
      }
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
}
