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

  /// GET /api/facility/beds?roomId=&status=&active=
  Future<List<Map<String, dynamic>>> listBeds({
    required String roomId,
    String? status,
    bool? active,
  }) async {
    final res = await _dio.get(
      '/api/facility/beds',
      queryParameters: {
        'roomId': roomId,
        if (status != null && status.trim().isNotEmpty) 'status': status.trim(),
        if (active != null) 'active': active.toString(),
      },
    );
    return _asListOfMap(res.data);
  }
}
