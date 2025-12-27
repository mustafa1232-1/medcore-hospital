// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:mobile/src_v2/workspaces/patient/services/patient_api.dart';

class PatientProfileService {
  static Map<String, dynamic> _unwrap(dynamic raw) {
    if (raw is Map) {
      final m = Map<String, dynamic>.from(raw);
      if (m['data'] is Map) return Map<String, dynamic>.from(m['data'] as Map);
      return m;
    }
    return const <String, dynamic>{};
  }

  static Future<Map<String, dynamic>> getMyProfile() async {
    final res = await PatientApi.get('/api/patient/profile');
    final out = _unwrap(res.data);

    // backend: { ok:true, data: profile }
    if (out.containsKey('patientAccountId') || out.containsKey('fullName'))
      return out;
    if (out['data'] is Map)
      return Map<String, dynamic>.from(out['data'] as Map);
    return out;
  }

  static Future<Map<String, dynamic>> patchMyProfile(
    Map<String, dynamic> patch,
  ) async {
    final res = await PatientApi.patch('/api/patient/profile', data: patch);
    final out = _unwrap(res.data);

    if (out.containsKey('patientAccountId') || out.containsKey('fullName'))
      return out;
    if (out['data'] is Map)
      return Map<String, dynamic>.from(out['data'] as Map);
    return out;
  }
}
