import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_service.dart';

class QiitaService {
  final tokenService = TokenService();

  /// =========================
  /// 記事一覧取得
  /// =========================
  Future<List<dynamic>> fetchItems() async {
    final token = await tokenService.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token未設定');
    }

    final response = await http.get(
      Uri.parse(
        'https://qiita.com/api/v2/authenticated_user/items?page=1&per_page=100',
      ),

      headers: {
        'Authorization': 'Bearer $token',

        'Connection': 'close',
      },
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Qiita API error: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw Exception('Unexpected response format');
    }

    return data;
  }

  /// =========================
  /// ユーザー情報取得
  /// =========================
  Future<Map<String, dynamic>> fetchUser() async {
    final token = await tokenService.loadToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token未設定');
    }

    final response = await http.get(
      Uri.parse(
        'https://qiita.com/api/v2/authenticated_user',
      ),

      headers: {
        'Authorization': 'Bearer $token',

        'Connection': 'close',
      },
    ).timeout(
      const Duration(seconds: 15),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Qiita User API error: ${response.statusCode}',
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected user response format');
    }

    return data;
  }
}