import 'package:dio/dio.dart';
import 'package:mobile/src/core/api/api_client.dart';

class LookupsApiServiceV2 {
  Dio get _dio => ApiClient.dio;

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }

    if (v is Map) {
      final m = v.cast<String, dynamic>();

      // common shapes:
      // { ok:true, items:[...] }
      // { items:[...] }
      // { departments:[...] }
      // { data:[...] }
      // { data:{ items:[...] } }
      dynamic items =
          m['items'] ?? m['departments'] ?? m['data'] ?? m['results'];

      if (items is Map) {
        final mm = items.cast<String, dynamic>();
        items = mm['items'] ?? mm['departments'] ?? mm['data'] ?? mm['results'];
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

  /// ✅ Correct endpoint for your current backend:
  /// GET /api/lookups/departments?q=&limit=
  Future<List<Map<String, dynamic>>> listDepartments({
    String q = '',
    int limit = 100,
  }) async {
    final res = await _dio.get(
      '/api/lookups/departments',
      queryParameters: {if (q.trim().isNotEmpty) 'q': q.trim(), 'limit': limit},
    );

    return _asListOfMap(res.data);
  }
}
