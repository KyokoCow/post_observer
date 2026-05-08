import 'dart:convert';

import 'package:http/http.dart' as http;

import 'token_service.dart';

class QiitaService {
  final tokenService = TokenService();

  Future<List<dynamic>> fetchItems() async {
    final token =
    await tokenService.loadToken();

    if (token == null ||
        token.isEmpty) {
      throw Exception('Token未設定');
    }

    final response = await http.get(
      Uri.parse(
        'https://qiita.com/api/v2/authenticated_user/items?page=1&per_page=100',
      ),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Qiita API error');
    }

    return jsonDecode(response.body);
  }
}