import 'package:dio/dio.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';
import 'package:mobile/src_v2/core/auth/patient_token_store.dart';

class PatientRegisterService {
  static Dio get _dio => ApiClient.dio;

  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['data'] is Map) return Map<String, dynamic>.from(m['data'] as Map);
      return m;
    }
    return const <String, dynamic>{};
  }

  static Future<void> register({
    required String fullName,
    String? phone,
    String? email,
    required String password,
  }) async {
    final Response res = await _dio.post(
      '/api/patient-auth/register',
      data: {
        'fullName': fullName.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        'password': password,
      },
    );

    final out = _unwrap(res.data);
    final token = (out['accessToken'] ?? out['token'] ?? '').toString();
    if (token.trim().isEmpty) {
      throw Exception('Register succeeded but accessToken missing');
    }

    await PatientTokenStore.saveAccessToken(token);
  }
}
