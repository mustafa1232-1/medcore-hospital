import 'package:dio/dio.dart';

import '../api/api_client.dart';

class AuthService {
  /// Login using tenant (code OR uuid) + (email or phone) + password
  static Future<Map<String, dynamic>> login({
    required String tenant,
    String? email,
    String? phone,
    required String password,
  }) async {
    final Response res = await ApiClient.dio.post(
      '/api/auth/login',
      data: {
        'tenant': tenant, // ✅ new
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'password': password,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  /// Register tenant + admin
  static Future<Map<String, dynamic>> registerTenant({
    required String name,
    required String type,
    String? phone,
    String? email,
    required String adminFullName,
    String? adminEmail,
    String? adminPhone,
    required String adminPassword,
  }) async {
    final Response res = await ApiClient.dio.post(
      '/api/auth/register-tenant',
      data: {
        'name': name,
        'type': type,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        'adminFullName': adminFullName,
        if (adminEmail != null && adminEmail.isNotEmpty)
          'adminEmail': adminEmail,
        if (adminPhone != null && adminPhone.isNotEmpty)
          'adminPhone': adminPhone,
        'adminPassword': adminPassword,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  /// Refresh tokens
  static Future<Map<String, dynamic>> refresh({
    required String refreshToken,
  }) async {
    final Response res = await ApiClient.dio.post(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    return Map<String, dynamic>.from(res.data);
  }

  /// Logout (invalidate refresh token)
  static Future<void> logout({required String refreshToken}) async {
    await ApiClient.dio.post(
      '/api/auth/logout',
      data: {'refreshToken': refreshToken},
    );
  }

  /// Get current user (/me)
  static Future<Map<String, dynamic>> me() async {
    final Response res = await ApiClient.dio.get('/api/me');
    return Map<String, dynamic>.from(res.data);
  }
}
