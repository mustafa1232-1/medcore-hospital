import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class PatientsApiService {
  const PatientsApiService();

  Dio get _dio => ApiClient.dio;

  Map<String, dynamic> _asMap(dynamic v) => Map<String, dynamic>.from(v as Map);

  /// unwrap {data: {...}} OR return raw map
  Map<String, dynamic> _unwrapMap(dynamic resData) {
    if (resData is Map && resData['data'] is Map) {
      return _asMap(resData['data']);
    }
    if (resData is Map) return _asMap(resData);
    return <String, dynamic>{};
  }

  /// unwrap list response:
  /// { items: [...], meta: {...} } OR { data: { items: [...]} } etc.
  Map<String, dynamic> _unwrapListResponse(dynamic resData) {
    if (resData is Map && resData['data'] is Map) {
      return _asMap(resData['data']);
    }
    if (resData is Map) return _asMap(resData);
    return <String, dynamic>{'items': <dynamic>[], 'meta': <String, dynamic>{}};
  }

  /// RECEPTION/ADMIN/DOCTOR: GET /api/patients?q=&phone=&limit=&offset=
  Future<Map<String, dynamic>> listPatients({
    String? q,
    String? phone,
    String? gender,
    bool? isActive,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/api/patients',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
        if (isActive != null) 'isActive': isActive,
        'limit': limit,
        'offset': offset,
      },
    );

    return _unwrapListResponse(res.data);
  }

  /// ✅ DOCTOR: GET /api/patients/assigned?q=&limit=&offset=
  Future<Map<String, dynamic>> listAssignedPatients({
    String? q,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/api/patients/assigned',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        'limit': limit,
        'offset': offset,
      },
    );

    return _unwrapListResponse(res.data);
  }

  /// RECEPTION/ADMIN: POST /api/patients
  Future<Map<String, dynamic>> createPatient({
    required String fullName,
    String? phone,
    String? email,
    String? gender, // MALE/FEMALE/OTHER
    String? dateOfBirth, // ISO yyyy-mm-dd
    String? nationalId,
    String? address,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/patients',
      data: {
        'fullName': fullName,
        'phone': (phone != null && phone.trim().isNotEmpty)
            ? phone.trim()
            : null,
        'email': (email != null && email.trim().isNotEmpty)
            ? email.trim()
            : null,
        'gender': (gender != null && gender.trim().isNotEmpty)
            ? gender.trim()
            : null,
        'dateOfBirth': (dateOfBirth != null && dateOfBirth.trim().isNotEmpty)
            ? dateOfBirth.trim()
            : null,
        'nationalId': (nationalId != null && nationalId.trim().isNotEmpty)
            ? nationalId.trim()
            : null,
        'address': (address != null && address.trim().isNotEmpty)
            ? address.trim()
            : null,
        'notes': (notes != null && notes.trim().isNotEmpty)
            ? notes.trim()
            : null,
      },
    );

    return _unwrapMap(res.data);
  }

  /// GET /api/patients/:id
  Future<Map<String, dynamic>> getPatientById(String id) async {
    final res = await _dio.get('/api/patients/$id');
    return _unwrapMap(res.data);
  }

  /// PATCH /api/patients/:id
  Future<Map<String, dynamic>> updatePatient(
    String id, {
    String? fullName,
    String? phone,
    String? email,
    String? gender,
    String? dateOfBirth,
    String? nationalId,
    String? address,
    String? notes,
  }) async {
    final data = <String, dynamic>{
      if (fullName != null) 'fullName': fullName,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth,
      if (nationalId != null) 'nationalId': nationalId,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
    };

    final res = await _dio.patch('/api/patients/$id', data: data);
    return _unwrapMap(res.data);
  }

  /// GET /api/patients/:id/medical-record
  Future<Map<String, dynamic>> getMedicalRecord(
    String id, {
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _dio.get(
      '/api/patients/$id/medical-record',
      queryParameters: {'limit': limit, 'offset': offset},
    );

    return _unwrapMap(res.data);
  }

  /// GET /api/patients/:id/health-advice
  Future<Map<String, dynamic>> getHealthAdvice(String id) async {
    final res = await _dio.get('/api/patients/$id/health-advice');
    return _unwrapMap(res.data);
  }

  Future<Map<String, dynamic>> issueJoinCode(String patientId) async {
    final res = await _dio.post('/api/patients/$patientId/join-code');
    return _unwrapMap(res.data);
  }

  Future<Map<String, dynamic>> externalHistory(String patientId) async {
    final res = await _dio.get('/api/patients/$patientId/external-history');
    return _unwrapMap(res.data);
  }

  // ✅ NEW: Patient lookup for pickers
  // GET /api/lookups/patients?q=&limit=
  Future<List<Map<String, dynamic>>> lookupPatients({
    String? q,
    int limit = 30,
  }) async {
    final res = await _dio.get(
      '/api/lookups/patients',
      queryParameters: {'q': (q ?? '').trim(), 'limit': limit},
    );

    final data = res.data;
    if (data is Map && data['items'] is List) {
      return (data['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    return const [];
  }
}
