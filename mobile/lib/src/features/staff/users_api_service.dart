import 'package:dio/dio.dart';

import '../../../src_v2/core/api/api_client.dart';

class UsersApiService {
  static Future<List<Map<String, dynamic>>> listUsers({
    String? q,
    bool? active,
    int? limit,
    int? offset,
  }) async {
    final Response res = await ApiClient.dio.get(
      '/api/users',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (active != null) 'active': active.toString(),
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      },
    );

    final data = Map<String, dynamic>.from(res.data);
    final list = (data['users'] as List?) ?? const [];

    return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  static Future<Map<String, dynamic>> createUser({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    required List<String> roles,
  }) async {
    final Response res = await ApiClient.dio.post(
      '/api/users',
      data: {
        'fullName': fullName,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        'password': password,
        'roles': roles,
      },
    );

    final data = Map<String, dynamic>.from(res.data);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  static Future<Map<String, dynamic>> setActive({
    required String userId,
    required bool isActive,
  }) async {
    final Response res = await ApiClient.dio.patch(
      '/api/users/$userId/active',
      data: {'isActive': isActive},
    );

    final data = Map<String, dynamic>.from(res.data);
    return Map<String, dynamic>.from(data['user'] as Map);
  }

  static Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    await ApiClient.dio.post(
      '/api/users/$userId/reset-password',
      data: {'newPassword': newPassword},
    );
  }
}

/// Helper: human readable dio error message
String dioMessage(Object e) {
  if (e is DioException) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return '${data['message']}';
    }

    if (status != null) return 'Request failed ($status)';
    return e.message ?? 'Network error';
  }
  return 'Unexpected error';
}
