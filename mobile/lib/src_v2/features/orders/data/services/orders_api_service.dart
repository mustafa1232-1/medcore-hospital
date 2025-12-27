// lib/src_v2/features/orders/data/services/orders_api_service.dart
import 'package:dio/dio.dart';
import '../../../../core/api/api_client.dart';

class OrdersApiService {
  const OrdersApiService();

  Dio get _dio => ApiClient.dio;

  // ---------------------------
  // ✅ Lookups (Patients / Drugs)
  // ---------------------------

  Future<List<Map<String, dynamic>>> lookupPatients({
    required String q,
    int limit = 30,
  }) async {
    final query = q.trim();

    // جرّب أكثر من مسار محتمل بدون ما نكسر أي شيء
    final candidates = <Future<Response>>[
      _dio.get(
        '/api/lookups/patients',
        queryParameters: {'q': query, 'limit': limit},
      ),
      _dio.get(
        '/api/patients/lookup',
        queryParameters: {'q': query, 'limit': limit},
      ),
      _dio.get('/api/patients', queryParameters: {'q': query, 'limit': limit}),
    ];

    return _firstListResult(candidates);
  }

  Future<List<Map<String, dynamic>>> lookupDrugs({
    required String q,
    int limit = 30,
  }) async {
    final query = q.trim();

    final candidates = <Future<Response>>[
      _dio.get(
        '/api/pharmacy/drugs',
        queryParameters: {'q': query, 'limit': limit},
      ),
      _dio.get(
        '/api/pharmacy/drug-catalog',
        queryParameters: {'q': query, 'limit': limit},
      ),
      _dio.get(
        '/api/lookups/drugs',
        queryParameters: {'q': query, 'limit': limit},
      ),
    ];

    return _firstListResult(candidates);
  }

  // helper: try endpoints until one returns a list
  Future<List<Map<String, dynamic>>> _firstListResult(
    List<Future<Response>> calls,
  ) async {
    DioException? lastDioError;
    dynamic lastData;

    for (final c in calls) {
      try {
        final res = await c;
        lastData = res.data;

        // support shapes:
        // 1) { ok:true, items:[...] }
        // 2) { items:[...] }
        // 3) { data:[...] }
        // 4) [...]
        final data = res.data;

        final List list = data is List
            ? data
            : (data is Map && data['items'] is List)
            ? data['items'] as List
            : (data is Map && data['data'] is List)
            ? data['data'] as List
            : const [];

        if (list.isNotEmpty ||
            (data is Map && (data['items'] is List || data['data'] is List))) {
          return list
              .whereType<Map>()
              .map((m) => m.cast<String, dynamic>())
              .toList();
        }
      } on DioException catch (e) {
        lastDioError = e;
        continue;
      } catch (_) {
        continue;
      }
    }

    // إذا ولا واحد نجح
    if (lastDioError != null) {
      // خلي الرسالة واضحة
      final status = lastDioError.response?.statusCode;
      throw Exception(
        'Lookup failed (status: ${status ?? '-'}) : ${lastDioError.message}\n$lastData',
      );
    }

    throw Exception('Lookup failed: no endpoint returned a list.');
  }

  // ---------------------------
  // Orders (as you already have)
  // ---------------------------

  Future<Map<String, dynamic>> createMedicationOrder({
    required String admissionId,
    required String medicationName,
    required String dose,
    required String route,
    required String frequency,
    String? duration,
    bool startNow = true,
    String? drugId,
    num? requestedQty,
    String? patientInstructionsAr,
    String? patientInstructionsEn,
    String? dosageText,
    String? frequencyText,
    String? durationText,
    bool? withFood,
    String? warningsText,
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/medication',
      data: {
        'admissionId': admissionId,
        'medicationName': medicationName,
        'dose': dose,
        'route': route,
        'frequency': frequency,
        'duration': duration,
        'startNow': startNow,
        'drugId': (drugId != null && drugId.isNotEmpty) ? drugId : null,
        'requestedQty': requestedQty,
        'patientInstructionsAr': patientInstructionsAr,
        'patientInstructionsEn': patientInstructionsEn,
        'dosageText': dosageText,
        'frequencyText': frequencyText,
        'durationText': durationText,
        'withFood': withFood,
        'warningsText': warningsText,
        'notes': notes,
      },
    );

    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> createLabOrder({
    required String admissionId,
    required String testName,
    String priority = 'ROUTINE',
    String specimen = 'BLOOD',
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/lab',
      data: {
        'admissionId': admissionId,
        'testName': testName,
        'priority': priority,
        'specimen': specimen,
        'notes': notes,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> createProcedureOrder({
    required String admissionId,
    required String procedureName,
    String urgency = 'NORMAL',
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/procedure',
      data: {
        'admissionId': admissionId,
        'procedureName': procedureName,
        'urgency': urgency,
        'notes': notes,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> listOrders({
    String? admissionId,
    String? patientId,
    String? kind,
    String? status,
    int limit = 20,
    int offset = 0,
  }) async {
    final Response res = await _dio.get(
      '/api/orders',
      queryParameters: {
        if (admissionId != null && admissionId.isNotEmpty)
          'admissionId': admissionId,
        if (patientId != null && patientId.isNotEmpty) 'patientId': patientId,
        if (kind != null && kind.isNotEmpty) 'kind': kind,
        if (status != null && status.isNotEmpty) 'status': status,
        'limit': limit,
        'offset': offset,
      },
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> getOrderById({required String id}) async {
    final Response res = await _dio.get('/api/orders/$id');
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> cancelOrder({
    required String id,
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/$id/cancel',
      data: {'notes': notes},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> pharmacyPrepare({
    required String orderId,
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/$orderId/pharmacy/prepare',
      data: {'notes': notes},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> pharmacyPartial({
    required String orderId,
    required num preparedQty,
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/$orderId/pharmacy/partial',
      data: {'preparedQty': preparedQty, 'notes': notes},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> pharmacyOutOfStock({
    required String orderId,
    String? notes,
  }) async {
    final Response res = await _dio.post(
      '/api/orders/$orderId/pharmacy/out-of-stock',
      data: {'notes': notes},
    );
    return Map<String, dynamic>.from(res.data);
  }

  Future<Map<String, dynamic>> listPatientMedications({
    int limit = 50,
    int offset = 0,
  }) async {
    final Response res = await _dio.get(
      '/api/orders/patient/medications',
      queryParameters: {'limit': limit, 'offset': offset},
    );
    return Map<String, dynamic>.from(res.data);
  }
}
