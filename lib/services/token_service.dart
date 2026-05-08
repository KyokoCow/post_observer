import 'package:shared_preferences/shared_preferences.dart';

class TokenService {
  static const key = 'qiita_token';

  Future<void> saveToken(
      String token,
      ) async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.setString(key, token);
  }

  Future<String?> loadToken() async {
    final prefs =
    await SharedPreferences.getInstance();

    return prefs.getString(key);
  }
}