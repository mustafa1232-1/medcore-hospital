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

  /// ❌ لا يُستخدم مباشرة بعد الآن
  /// (أبقيناه فقط للتوافق إن كان مستعملًا في مكان آخر)
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

  /// ✅ المرحلة 2 (المهم)
  /// POST /api/facility/departments/activate
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
