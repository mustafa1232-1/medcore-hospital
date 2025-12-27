import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class AdmissionsApiService {
  const AdmissionsApiService();

  Dio get _dio => ApiClient.dio;

  Map<String, dynamic> _asMap(dynamic v) => Map<String, dynamic>.from(v as Map);

  Map<String, dynamic> _unwrapMap(dynamic resData) {
    if (resData is Map && resData['data'] is Map) {
      return _asMap(resData['data']);
    }
    if (resData is Map) return _asMap(resData);
    return <String, dynamic>{};
  }

  /// Extract "id" from:
  /// 1) { data: { id: ... } }
  /// 2) { id: ... }
  /// 3) { data: { admission: { id: ... } } }  (fallback)
  String _extractId(dynamic resData) {
    if (resData is Map) {
      final m = Map<String, dynamic>.from(resData);

      if (m['data'] is Map) {
        final d = Map<String, dynamic>.from(m['data'] as Map);

        final id1 = (d['id'] ?? '').toString().trim();
        if (id1.isNotEmpty) return id1;

        // fallback if server returns {data:{admission:{id}}}
        if (d['admission'] is Map) {
          final a = Map<String, dynamic>.from(d['admission'] as Map);
          final id2 = (a['id'] ?? '').toString().trim();
          if (id2.isNotEmpty) return id2;
        }
      }

      final id0 = (m['id'] ?? '').toString().trim();
      if (id0.isNotEmpty) return id0;
    }
    return '';
  }

  /// ✅ Create inpatient admission (PENDING)
  /// POST /api/admissions
  Future<String> createAdmission({
    required String patientId,
    String? assignedDoctorUserId,
    String? reason,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/admissions',
      data: {
        'patientId': patientId,
        'assignedDoctorUserId': assignedDoctorUserId, // optional
        'reason': reason,
        'notes': notes,
      },
    );

    final id = _extractId(res.data);
    if (id.isEmpty) {
      throw Exception('Backend did not return admission id');
    }
    return id;
  }

  /// ✅ Assign bed to admission
  /// POST /api/admissions/:id/assign-bed
  Future<Map<String, dynamic>> assignBed({
    required String admissionId,
    required String bedId,
  }) async {
    final res = await _dio.post(
      '/api/admissions/$admissionId/assign-bed',
      data: {'bedId': bedId},
    );
    return _unwrapMap(res.data);
  }

  /// ✅ Get active admission id for patient (used in your patients list)
  /// GET /api/admissions/active?patientId=...
  Future<String?> getActiveAdmissionIdForPatient({
    required String patientId,
  }) async {
    final res = await _dio.get(
      '/api/admissions/active',
      queryParameters: {'patientId': patientId},
    );

    final data = _unwrapMap(res.data);
    final id = (data['admissionId'] ?? '').toString().trim();
    return id.isEmpty ? null : id;
  }

  /// ✅ Doctor creates outpatient visit (ACTIVE no bed)
  /// POST /api/admissions/outpatient
  Future<String> createOutpatientVisit({
    required String patientId,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/admissions/outpatient',
      data: {'patientId': patientId, 'notes': notes},
    );

    final id = _extractId(res.data);
    if (id.isEmpty) {
      throw Exception('Backend did not return admission id');
    }
    return id;
  }
}
