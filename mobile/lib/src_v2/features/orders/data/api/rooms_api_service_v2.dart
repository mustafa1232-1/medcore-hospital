import 'package:dio/dio.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';

class RoomsApiServiceV2 {
  Dio get _dio => ApiClient.dio;

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is Map) {
      final m = v.cast<String, dynamic>();
      dynamic items = m['items'] ?? m['data'] ?? m['rooms'] ?? m['results'];
      if (items is Map) {
        final mm = items.cast<String, dynamic>();
        items = mm['items'] ?? mm['data'] ?? mm['rooms'] ?? mm['results'];
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

  /// GET /api/facility/rooms?departmentId=...&query=...&active=...
  Future<List<Map<String, dynamic>>> listRooms({
    required String departmentId,
    String query = '',
    bool? active,
  }) async {
    final res = await _dio.get(
      '/api/facility/rooms',
      queryParameters: {
        'departmentId': departmentId,
        if (query.trim().isNotEmpty) 'query': query.trim(),
        if (active != null) 'active': active.toString(),
      },
    );
    return _asListOfMap(res.data);
  }

  /// POST /api/facility/rooms
  /// backend generates code if null/empty
  Future<Map<String, dynamic>> createRoom({
    required String departmentId,
    String? code,
    required String name,
    int? floor,
    bool isActive = true,
  }) async {
    final res = await _dio.post(
      '/api/facility/rooms',
      data: {
        'departmentId': departmentId,
        'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
        'name': name.trim(),
        'floor': floor,
        'isActive': isActive,
      },
    );
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// PATCH /api/facility/rooms/:id
  Future<Map<String, dynamic>> updateRoom({
    required String id,
    String? departmentId,
    String? code,
    String? name,
    int? floor,
    bool? isActive,
  }) async {
    final res = await _dio.patch(
      '/api/facility/rooms/$id',
      data: {
        if (departmentId != null) 'departmentId': departmentId,
        if (code != null) 'code': code.trim(),
        if (name != null) 'name': name.trim(),
        if (floor != null) 'floor': floor,
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// DELETE /api/facility/rooms/:id
  Future<Map<String, dynamic>> deleteRoom(String id) async {
    final res = await _dio.delete('/api/facility/rooms/$id');
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }
}
