import 'package:dio/dio.dart';
import 'package:mobile/src/core/api/api_client.dart';

class BedsApiServiceV2 {
  Dio get _dio => ApiClient.dio;

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is Map) {
      final m = v.cast<String, dynamic>();
      dynamic items = m['items'] ?? m['data'] ?? m['beds'] ?? m['results'];
      if (items is Map) {
        final mm = items.cast<String, dynamic>();
        items = mm['items'] ?? mm['data'] ?? mm['beds'] ?? mm['results'];
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

  /// GET /api/facility/beds?roomId=...&active=...
  Future<List<Map<String, dynamic>>> listBeds({
    required String roomId,
    bool? active,
  }) async {
    final res = await _dio.get(
      '/api/facility/beds',
      queryParameters: {
        'roomId': roomId,
        if (active != null) 'active': active.toString(),
      },
    );
    return _asListOfMap(res.data);
  }

  /// POST /api/facility/beds
  Future<Map<String, dynamic>> createBed({
    required String roomId,
    String? code,
    String status = 'AVAILABLE',
    String? notes,
    bool isActive = true,
  }) async {
    final res = await _dio.post(
      '/api/facility/beds',
      data: {
        'roomId': roomId,
        'code': (code?.trim().isEmpty ?? true) ? null : code!.trim(),
        'status': status,
        'notes': (notes?.trim().isEmpty ?? true) ? null : notes!.trim(),
        'isActive': isActive,
      },
    );
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// PATCH /api/facility/beds/:id
  Future<Map<String, dynamic>> updateBed({
    required String id,
    String? roomId,
    String? code,
    String? notes,
    bool? isActive,
  }) async {
    final res = await _dio.patch(
      '/api/facility/beds/$id',
      data: {
        if (roomId != null) 'roomId': roomId,
        if (code != null) 'code': code.trim(),
        if (notes != null)
          'notes': (notes.trim().isEmpty) ? null : notes.trim(),
        if (isActive != null) 'isActive': isActive,
      },
    );
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// POST /api/facility/beds/:id/status
  Future<Map<String, dynamic>> changeStatus({
    required String id,
    required String status,
  }) async {
    final res = await _dio.post(
      '/api/facility/beds/$id/status',
      data: {'status': status},
    );
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }

  /// DELETE /api/facility/beds/:id
  Future<Map<String, dynamic>> deleteBed(String id) async {
    final res = await _dio.delete('/api/facility/beds/$id');
    final data = _asMap(res.data);
    final d = data['data'];
    if (d is Map) return d.cast<String, dynamic>();
    return data;
  }
}
