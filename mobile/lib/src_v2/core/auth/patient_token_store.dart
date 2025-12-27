import 'package:shared_preferences/shared_preferences.dart';

class PatientTokenStore {
  static const _kAccess = 'patient_access_token';

  static Future<void> saveAccessToken(String token) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kAccess, token);
  }

  static Future<String?> getAccessToken() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString(_kAccess);
    if (t == null || t.trim().isEmpty) return null;
    return t;
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kAccess);
  }
}
