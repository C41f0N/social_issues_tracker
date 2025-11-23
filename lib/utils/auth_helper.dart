import 'package:hive_flutter/hive_flutter.dart';

class AuthHelper {
  static const _tokenKey = 'auth_token';

  /// Get the current auth token from Hive
  static Future<String?> getToken() async {
    final box = await Hive.openBox('auth');
    return box.get(_tokenKey);
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null;
  }
}
