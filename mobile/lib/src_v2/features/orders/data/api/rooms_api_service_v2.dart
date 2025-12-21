import 'package:dio/dio.dart';
import 'package:mobile/src/core/api/api_client.dart';

class RoomsApiServiceV2 {
  Dio get _dio => ApiClient.dio;

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is Map) {
      final m = v.cast<String, dynamic>();
      dynamic items = m['items'] ?? m['data'] ?? m['results'];
      if (items is Map) {
        final mm = items.cast<String, dynamic>();
        items = mm['items'] ?? mm['data'] ?? mm['results'];
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

  /// GET /api/facility/rooms?departmentId=&query=&active=
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
}
