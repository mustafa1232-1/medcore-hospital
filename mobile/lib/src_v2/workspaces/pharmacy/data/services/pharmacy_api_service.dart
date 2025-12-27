// lib/src_v2/workspaces/pharmacy/data/services/pharmacy_api_service.dart
// ignore_for_file: curly_braces_in_flow_control_structures, unused_field

import 'package:dio/dio.dart';
import 'package:mobile/src_v2/core/api/api_client.dart';

class PharmacyApiService {
  Dio get _dio => ApiClient.dio;

  static const String _base = '/api/pharmacy';
  static const String _warehouses = '$_base/warehouses';
  static const String _drugs = '$_base/drugs';

  // ✅ موجود بالباك اند
  static const String _stockBalance = '$_base/stock/balance';
  static const String _stockLedger = '$_base/stock/ledger';

  // ✅ موجود بالباك اند
  static const String _stockRequests = '$_base/stock-requests';

  // ✅ Lookups
  static const String _lookupsStaff = '/api/lookups/staff';

  // =======================
  // Casting helpers (safe)
  // =======================
  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      final out = <String, dynamic>{};
      v.forEach((key, value) {
        out['$key'] = value;
      });
      return out;
    }
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    // 1) Direct list
    if (v is List) {
      return v.whereType<Map>().map((e) => _asMap(e)).toList(growable: false);
    }

    // 2) Wrapped map (common API shapes)
    if (v is Map) {
      final m = _asMap(v);

      dynamic items = m['items'] ?? m['data'] ?? m['results'];

      // Sometimes nested: { data: { items: [...] } }
      if (items is Map) {
        final mm = _asMap(items);
        items = mm['items'] ?? mm['data'] ?? mm['results'];
      }

      // Sometimes: { data: [...] }
      if (items is List) {
        return items
            .whereType<Map>()
            .map((e) => _asMap(e))
            .toList(growable: false);
      }
    }

    return const <Map<String, dynamic>>[];
  }

  String _serverMessage(dynamic data) {
    final m = _asMap(data);
    final msg = (m['message'] ?? m['error'] ?? m['details'] ?? '')
        .toString()
        .trim();
    return msg.isEmpty ? 'Request failed' : msg;
  }

  void _ensureOk(Response res) {
    final code = res.statusCode ?? 0;
    if (code >= 400) throw Exception(_serverMessage(res.data));
  }

  Never _throwDio(DioException e) {
    final data = e.response?.data;
    throw Exception(
      data != null ? _serverMessage(data) : (e.message ?? 'Dio error'),
    );
  }

  // =======================
  // ✅ STAFF LOOKUP (Pharmacists)
  // GET /api/lookups/staff?role=PHARMACY&q=&limit=&offset=
  // =======================
  Future<List<Map<String, dynamic>>> listPharmacists({
    String q = '',
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get(
        _lookupsStaff,
        queryParameters: {
          'role': 'PHARMACY',
          if (q.trim().isNotEmpty) 'q': q.trim(),
          'limit': limit,
          'offset': offset,
        },
      );

      _ensureOk(res);

      final m = _asMap(res.data);
      return _asListOfMap(m['items'] ?? res.data);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  // =======================
  // ✅ WAREHOUSES
  // =======================
  Future<List<Map<String, dynamic>>> listWarehouses({
    int limit = 200,
    int offset = 0,
    bool activeOnly = true,
  }) async {
    try {
      final res = await _dio.get(
        _warehouses,
        queryParameters: {
          'limit': limit,
          'offset': offset,
          if (activeOnly) 'active': true,
        },
      );

      _ensureOk(res);
      return _asListOfMap(res.data);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<Map<String, dynamic>?> getFirstWarehouse() async {
    final items = await listWarehouses(limit: 10, offset: 0, activeOnly: true);
    if (items.isEmpty) return null;
    return items.first;
  }

  Future<Map<String, dynamic>> createWarehouse({
    required String name,
    String? code,
    required String pharmacistUserId,
    bool isActive = true,
  }) async {
    try {
      final res = await _dio.post(
        _warehouses,
        data: {
          'name': name.trim(),
          'code': (code ?? '').trim(),
          'isActive': isActive,
          'pharmacistUserId': pharmacistUserId,
        },
      );

      _ensureOk(res);

      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  // =======================
  // ✅ DRUGS
  // =======================
  Future<List<Map<String, dynamic>>> listDrugs({
    String q = '',
    int limit = 200,
    int offset = 0,
    bool activeOnly = true,
  }) async {
    try {
      final res = await _dio.get(
        _drugs,
        queryParameters: {
          if (q.trim().isNotEmpty) 'q': q.trim(),
          'limit': limit,
          'offset': offset,
          if (activeOnly) 'active': true,
        },
      );

      _ensureOk(res);
      return _asListOfMap(res.data);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  /// ✅ Create Drug (supports new columns in drug_catalog)
  Future<Map<String, dynamic>> createDrug({
    required String name,
    String? genericName,
    String? brandName,
    String? code,
    String? barcode,
    String? form,
    String? strength,
    String? route,
    String? patientInstructionsAr,
    String? patientInstructionsEn,
    String? dosageText,
    String? frequencyText,
    String? durationText,
    bool? withFood,
    String? warningsText,
    bool isActive = true,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        'name': name.trim(),
        if (genericName != null) 'genericName': genericName.trim(),
        if (brandName != null) 'brandName': brandName.trim(),
        if (code != null) 'code': code.trim(),
        if (barcode != null) 'barcode': barcode.trim(),
        if (form != null) 'form': form.trim(),
        if (strength != null) 'strength': strength.trim(),
        if (route != null) 'route': route.trim(),
        'isActive': isActive,
        if (notes != null) 'notes': notes.trim(),

        // snake_case
        if (patientInstructionsAr != null)
          'patient_instructions_ar': patientInstructionsAr.trim(),
        if (patientInstructionsEn != null)
          'patient_instructions_en': patientInstructionsEn.trim(),
        if (dosageText != null) 'dosage_text': dosageText.trim(),
        if (frequencyText != null) 'frequency_text': frequencyText.trim(),
        if (durationText != null) 'duration_text': durationText.trim(),
        if (withFood != null) 'with_food': withFood,
        if (warningsText != null) 'warnings_text': warningsText.trim(),

        // camelCase (احتياط)
        if (patientInstructionsAr != null)
          'patientInstructionsAr': patientInstructionsAr.trim(),
        if (patientInstructionsEn != null)
          'patientInstructionsEn': patientInstructionsEn.trim(),
        if (dosageText != null) 'dosageText': dosageText.trim(),
        if (frequencyText != null) 'frequencyText': frequencyText.trim(),
        if (durationText != null) 'durationText': durationText.trim(),
        if (withFood != null) 'withFood': withFood,
        if (warningsText != null) 'warningsText': warningsText.trim(),
      };

      final res = await _dio.post(_drugs, data: payload);
      _ensureOk(res);

      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  // ✅ NEW: GET Drug by ID
  Future<Map<String, dynamic>> getDrugById(String id) async {
    try {
      final res = await _dio.get('$_drugs/$id');
      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  // ✅ NEW: PATCH Update Drug (no quantity fields here)
  Future<Map<String, dynamic>> updateDrug({
    required String id,

    String? name,
    String? genericName,
    String? brandName,
    String? code,
    String? barcode,
    String? form,
    String? strength,
    String? route,

    String? patientInstructionsAr,
    String? patientInstructionsEn,
    String? dosageText,
    String? frequencyText,
    String? durationText,
    bool? withFood,
    String? warningsText,

    bool? isActive,
    String? notes,
  }) async {
    try {
      final payload = <String, dynamic>{
        if (name != null) 'name': name.trim(),
        if (genericName != null) 'genericName': genericName.trim(),
        if (brandName != null) 'brandName': brandName.trim(),
        if (code != null) 'code': code.trim(),
        if (barcode != null) 'barcode': barcode.trim(),
        if (form != null) 'form': form.trim(),
        if (strength != null) 'strength': strength.trim(),
        if (route != null) 'route': route.trim(),

        if (isActive != null) 'isActive': isActive,
        if (notes != null) 'notes': notes.trim(),

        // snake_case
        if (patientInstructionsAr != null)
          'patient_instructions_ar': patientInstructionsAr.trim(),
        if (patientInstructionsEn != null)
          'patient_instructions_en': patientInstructionsEn.trim(),
        if (dosageText != null) 'dosage_text': dosageText.trim(),
        if (frequencyText != null) 'frequency_text': frequencyText.trim(),
        if (durationText != null) 'duration_text': durationText.trim(),
        if (withFood != null) 'with_food': withFood,
        if (warningsText != null) 'warnings_text': warningsText.trim(),

        // camelCase (احتياط)
        if (patientInstructionsAr != null)
          'patientInstructionsAr': patientInstructionsAr.trim(),
        if (patientInstructionsEn != null)
          'patientInstructionsEn': patientInstructionsEn.trim(),
        if (dosageText != null) 'dosageText': dosageText.trim(),
        if (frequencyText != null) 'frequencyText': frequencyText.trim(),
        if (durationText != null) 'durationText': durationText.trim(),
        if (withFood != null) 'withFood': withFood,
        if (warningsText != null) 'warningsText': warningsText.trim(),
      };

      final res = await _dio.patch('$_drugs/$id', data: payload);
      _ensureOk(res);

      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  // =======================
  // ✅ INVENTORY
  // =======================
  Future<List<Map<String, dynamic>>> getInventorySnapshot({
    required String warehouseId,
    String q = '',
    int limit = 200,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get(
        _stockBalance,
        queryParameters: {
          'warehouseId': warehouseId,
          if (q.trim().isNotEmpty) 'q': q.trim(),
          'limit': limit,
          'offset': offset,
        },
      );

      _ensureOk(res);
      return _asListOfMap(res.data);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  // =======================
  // ✅ STOCK REQUESTS
  // =======================
  Future<Map<String, dynamic>> listStockRequestsRaw({
    String? status,
    String? kind,
    String? fromWarehouseId,
    String? toWarehouseId,
    String? patientId,
    String? admissionId,
    String? orderId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final res = await _dio.get(
        _stockRequests,
        queryParameters: {
          if (status != null && status.trim().isNotEmpty)
            'status': status.trim(),
          if (kind != null && kind.trim().isNotEmpty) 'kind': kind.trim(),
          if (fromWarehouseId != null && fromWarehouseId.trim().isNotEmpty)
            'fromWarehouseId': fromWarehouseId.trim(),
          if (toWarehouseId != null && toWarehouseId.trim().isNotEmpty)
            'toWarehouseId': toWarehouseId.trim(),
          if (patientId != null && patientId.trim().isNotEmpty)
            'patientId': patientId.trim(),
          if (admissionId != null && admissionId.trim().isNotEmpty)
            'admissionId': admissionId.trim(),
          if (orderId != null && orderId.trim().isNotEmpty)
            'orderId': orderId.trim(),
          'limit': limit,
          'offset': offset,
        },
      );

      _ensureOk(res);
      return _asMap(res.data);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<List<Map<String, dynamic>>> listStockRequests({
    String? status,
    String? kind,
    String? fromWarehouseId,
    String? toWarehouseId,
    String? patientId,
    String? admissionId,
    String? orderId,
    int limit = 50,
    int offset = 0,
  }) async {
    final raw = await listStockRequestsRaw(
      status: status,
      kind: kind,
      fromWarehouseId: fromWarehouseId,
      toWarehouseId: toWarehouseId,
      patientId: patientId,
      admissionId: admissionId,
      orderId: orderId,
      limit: limit,
      offset: offset,
    );

    final data = raw['items'] ?? raw['data'] ?? raw;
    return _asListOfMap(data);
  }

  Future<Map<String, dynamic>> getStockRequestDetails(String id) async {
    try {
      final res = await _dio.get('$_stockRequests/$id');
      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<Map<String, dynamic>> createStockRequest({
    required String kind,
    String? fromWarehouseId,
    String? toWarehouseId,
    String? patientId,
    String? admissionId,
    String? orderId,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        _stockRequests,
        data: {
          'kind': kind,
          'fromWarehouseId': fromWarehouseId,
          'toWarehouseId': toWarehouseId,
          'patientId': patientId,
          'admissionId': admissionId,
          'orderId': orderId,
          'notes': notes,
        },
      );

      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<Map<String, dynamic>> addStockRequestLine({
    required String requestId,
    required String drugId,
    required num qty,
    String? lotNumber,
    String? expiryDate,
    num? unitCost,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '$_stockRequests/$requestId/lines',
        data: {
          'drugId': drugId,
          'qty': qty,
          'lotNumber': lotNumber,
          'expiryDate': expiryDate,
          'unitCost': unitCost,
          'notes': notes,
        },
      );

      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<void> deleteStockRequestLine({
    required String requestId,
    required String lineId,
  }) async {
    try {
      final res = await _dio.delete('$_stockRequests/$requestId/lines/$lineId');
      _ensureOk(res);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<Map<String, dynamic>> submitStockRequest({
    required String requestId,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '$_stockRequests/$requestId/submit',
        data: {'notes': notes},
      );

      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<Map<String, dynamic>> approveStockRequest({
    required String id,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '$_stockRequests/$id/approve',
        data: {'notes': notes},
      );

      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }

  Future<Map<String, dynamic>> rejectStockRequest({
    required String id,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '$_stockRequests/$id/reject',
        data: {'notes': notes},
      );

      _ensureOk(res);
      final m = _asMap(res.data);
      return _asMap(m['data'] ?? m);
    } on DioException catch (e) {
      _throwDio(e);
    }
  }
}
