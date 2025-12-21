import 'package:dio/dio.dart';
import 'package:mobile/src/core/api/api_client.dart';

class DepartmentsApiServiceV2 {
  Dio get _dio => ApiClient.dio;

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is Map) {
      final m = v.cast<String, dynamic>();
      dynamic items =
          m['items'] ?? m['data'] ?? m['departments'] ?? m['results'];
      if (items is Map) {
        final mm = items.cast<String, dynamic>();
        items = mm['items'] ?? mm['data'] ?? mm['departments'] ?? mm['results'];
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

  /// ✅ Facility departments (protected by permissions)
  /// GET /api/departments?query=&active=
  Future<List<Map<String, dynamic>>> listDepartments({
    String query = '',
    bool? active,
  }) async {
    final res = await _dio.get(
      '/api/departments',
      queryParameters: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        if (active != null) 'active': active.toString(),
      },
    );
    return _asListOfMap(res.data);
  }

  /// POST /api/departments
  /// body: { code?: string, name: string, isActive?: bool }
  /// POST /api/departments
  /// body: { code?: string, name: string, isActive?: bool, roomsCount?: int, bedsPerRoom?: int }
  Future<Map<String, dynamic>> createDepartment({
    String? code,
    required String name,
    bool isActive = true,

    // ✅ NEW
    int? roomsCount,
    int? bedsPerRoom,
  }) async {
    final res = await _dio.post(
      '/api/departments',
      data: {
        'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
        'name': name.trim(),
        'isActive': isActive,

        // ✅ send only when provided
        if (roomsCount != null) 'roomsCount': roomsCount,
        if (bedsPerRoom != null) 'bedsPerRoom': bedsPerRoom,
      },
    );

    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// PATCH /api/departments/:id
  Future<Map<String, dynamic>> updateDepartment({
    required String id,
    String? code,
    String? name,
    bool? isActive,
  }) async {
    final res = await _dio.patch(
      '/api/departments/$id',
      data: {
        if (code != null) 'code': code.trim(),
        if (name != null) 'name': name.trim(),
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// DELETE /api/departments/:id  (soft delete -> is_active=false in backend)
  Future<Map<String, dynamic>> deleteDepartment(String id) async {
    final res = await _dio.delete('/api/departments/$id');
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }
}
