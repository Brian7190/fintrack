import 'package:shared_preferences/shared_preferences.dart';

class SessionPreferences {
  SessionPreferences._();

  static const String _rememberSessionKey = 'remember_session';

  // ====================================================
  // OBTENER PREFERENCIA
  // ====================================================

  static Future<bool> getRememberSession() async {
    final preferences = await SharedPreferences.getInstance();

    return preferences.getBool(_rememberSessionKey) ?? false;
  }

  // ====================================================
  // GUARDAR PREFERENCIA
  // ====================================================

  static Future<void> setRememberSession(bool value) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setBool(_rememberSessionKey, value);
  }

  // ====================================================
  // ELIMINAR PREFERENCIA
  // ====================================================

  static Future<void> clearRememberSession() async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.remove(_rememberSessionKey);
  }
}
