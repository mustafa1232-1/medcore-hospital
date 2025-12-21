import 'package:dio/dio.dart';
import 'package:mobile/src/core/api/api_client.dart';

class UsersApiServiceV2 {
  Dio get _dio => ApiClient.dio;

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is Map) {
      final m = v.cast<String, dynamic>();
      dynamic items = m['users'] ?? m['items'] ?? m['data'] ?? m['results'];
      if (items is Map) {
        final mm = items.cast<String, dynamic>();
        items = mm['users'] ?? mm['items'] ?? mm['data'] ?? mm['results'];
      }
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => e.cast<String, dynamic>())
            .toList();
      }
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return v.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  Future<List<Map<String, dynamic>>> listUsers({
    String q = '',
    bool? active,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/api/users',
      queryParameters: {
        if (q.trim().isNotEmpty) 'q': q.trim(),
        if (active != null) 'active': active.toString(),
        'limit': limit,
        'offset': offset,
      },
    );

    return _asListOfMap(res.data);
  }

  Future<Map<String, dynamic>> createUser({
    required String fullName,
    String? email,
    String? phone,
    required String password,
    required List<String> roles,
    String? departmentId, // optional
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName.trim(),
      'email': (email?.trim().isEmpty ?? true) ? null : email!.trim(),
      'phone': (phone?.trim().isEmpty ?? true) ? null : phone!.trim(),
      'password': password,
      'roles': roles,
    };

    // ✅ do NOT send unless you are sure backend supports it
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      payload['departmentId'] = departmentId.trim();
    }

    final res = await _dio.post('/api/users', data: payload);

    // expected: { ok:true, user:{...} }
    final data = _asMap(res.data);
    final user = data['user'];
    if (user is Map) return user.cast<String, dynamic>();

    // fallback
    return data;
  }

  Future<void> setActive(String userId, bool isActive) async {
    await _dio.patch('/api/users/$userId/active', data: {'isActive': isActive});
  }

  Future<void> resetPassword(String userId, String newPassword) async {
    await _dio.post(
      '/api/users/$userId/reset-password',
      data: {'newPassword': newPassword},
    );
  }
}
