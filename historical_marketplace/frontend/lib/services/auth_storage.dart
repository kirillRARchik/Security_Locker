/// Простое хранение токена авторизации в памяти.
/// После логина сохраняйте токен через [AuthStorage.saveToken].
/// Для персистентного хранения можно подключить shared_preferences.
class AuthStorage {
  static String? _token;

  static Future<String?> getToken() async {
    return _token;
  }

  static Future<void> saveToken(String token) async {
    _token = token;
  }

  static Future<void> clearToken() async {
    _token = null;
  }
}
