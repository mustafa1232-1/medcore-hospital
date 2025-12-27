import 'package:mobile/src_v2/workspaces/patient/services/patient_api.dart';

class PatientMedicationsService {
  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['data'] is Map) return Map<String, dynamic>.from(m['data'] as Map);
      return m;
    }
    return const <String, dynamic>{};
  }

  static Future<List<Map<String, dynamic>>> listMyMedications({
    required String tenantId,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await PatientApi.get(
      '/api/patient/tenants/$tenantId/medications',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    final out = _unwrap(res.data);

    // your controller returns { data } where data = { items, meta } OR { items,... } depending on implementation
    if (out['items'] is List) {
      return List<Map<String, dynamic>>.from(out['items'] as List);
    }
    if (out['data'] is Map && (out['data'] as Map)['items'] is List) {
      return List<Map<String, dynamic>>.from(
        (out['data'] as Map)['items'] as List,
      );
    }
    if (out['data'] is List) {
      return List<Map<String, dynamic>>.from(out['data'] as List);
    }

    return const <Map<String, dynamic>>[];
  }
}
