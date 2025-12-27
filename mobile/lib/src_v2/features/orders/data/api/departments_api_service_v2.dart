// lib/src_v2/features/orders/data/api/departments_api_service_v2.dart
import 'package:dio/dio.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';

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

      // ✅ Support nested "data" shape (e.g. { ok:true, data:{ items:[...] } })
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

  /// ✅ Tenant activated departments
  /// GET /api/facility/departments
  Future<List<Map<String, dynamic>>> listDepartments({
    String query = '',
    bool? active,
  }) async {
    final res = await _dio.get(
      '/api/facility/departments',
      queryParameters: {
        if (query.trim().isNotEmpty) 'query': query.trim(),
        if (active != null) 'active': active.toString(),
      },
    );
    return _asListOfMap(res.data);
  }

  /// ❌ legacy manual create (keep)
  Future<Map<String, dynamic>> createDepartment({
    String? code,
    required String name,
    bool isActive = true,
  }) async {
    final res = await _dio.post(
      '/api/facility/departments',
      data: {
        'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
        'name': name.trim(),
        'isActive': isActive,
      },
    );

    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// ✅ المرحلة 2
  /// POST /api/facility/departments/activate
  /// roomsCount / bedsPerRoom defaults are 1 on backend, we also default here.
  Future<Map<String, dynamic>> activateDepartment({
    required String systemDepartmentId,
    int roomsCount = 1,
    int bedsPerRoom = 1,
  }) async {
    final res = await _dio.post(
      '/api/facility/departments/activate',
      data: {
        'systemDepartmentId': systemDepartmentId,
        'roomsCount': roomsCount,
        'bedsPerRoom': bedsPerRoom,
      },
    );

    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// ✅ NEW: overview
  /// GET /api/facility/departments/:id/overview
  ///
  /// Supports backend shapes:
  /// - { ok:true, data:{...} }
  /// - { data:{...} }
  /// - { ...direct... }
  Future<Map<String, dynamic>> getDepartmentOverview(String id) async {
    final res = await _dio.get('/api/facility/departments/$id/overview');
    final root = _asMap(res.data);

    final d1 = root['data'];
    if (d1 is Map) return d1.cast<String, dynamic>();

    return root;
  }

  /// PATCH /api/facility/departments/:id
  Future<Map<String, dynamic>> updateDepartment({
    required String id,
    String? code,
    String? name,
    bool? isActive,
  }) async {
    final res = await _dio.patch(
      '/api/facility/departments/$id',
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

  /// DELETE /api/facility/departments/:id
  Future<Map<String, dynamic>> deleteDepartment(String id) async {
    final res = await _dio.delete('/api/facility/departments/$id');
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }
}
