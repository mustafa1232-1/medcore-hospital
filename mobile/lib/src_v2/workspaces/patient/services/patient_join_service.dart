import 'package:mobile/src_v2/workspaces/patient/services/patient_api.dart';

class PatientJoinService {
  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['data'] is Map) return Map<String, dynamic>.from(m['data'] as Map);
      return m;
    }
    return const <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> joinFacility({
    required String tenantId,
    required String patientId,
    required String joinCode,
  }) async {
    final res = await PatientApi.post(
      '/api/patient-join/join',
      data: {
        'tenantId': tenantId.trim(),
        'patientId': patientId.trim(),
        'joinCode': joinCode.trim(),
      },
    );
    return _unwrap(res.data);
  }

  static Future<Map<String, dynamic>> leaveFacility({
    required String tenantId,
  }) async {
    final res = await PatientApi.post(
      '/api/patient-join/tenants/$tenantId/leave',
      data: const {},
    );
    return _unwrap(res.data);
  }
}
