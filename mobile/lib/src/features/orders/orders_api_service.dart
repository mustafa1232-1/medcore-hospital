import 'package:dio/dio.dart';
import '../../../src_v2/core/api/api_client.dart';

class OrdersApiService {
  OrdersApiService();

  // ✅ ApiClient في مشروعك static
  Dio get _dio => ApiClient.dio;

  Future<Map<String, dynamic>> createMedicationOrder({
    required String admissionId,
    required String medicationName,
    required String dose,
    required String route,
    required String frequency,
    String? duration,
    bool startNow = true,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/orders/medication',
      data: {
        'admissionId': admissionId,
        'medicationName': medicationName,
        'dose': dose,
        'route': route,
        'frequency': frequency,
        'duration': duration,
        'startNow': startNow,
        'notes': notes,
      },
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createLabOrder({
    required String admissionId,
    required String testName,
    String priority = 'ROUTINE',
    String specimen = 'BLOOD',
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/orders/lab',
      data: {
        'admissionId': admissionId,
        'testName': testName,
        'priority': priority,
        'specimen': specimen,
        'notes': notes,
      },
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<Map<String, dynamic>> createProcedureOrder({
    required String admissionId,
    required String procedureName,
    String urgency = 'NORMAL',
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/orders/procedure',
      data: {
        'admissionId': admissionId,
        'procedureName': procedureName,
        'urgency': urgency,
        'notes': notes,
      },
    );

    return Map<String, dynamic>.from(res.data as Map);
  }

  Future<dynamic> listOrders({
    String? search,
    String? status,
    String? priority,
    String? target,
  }) async {}

  Future<dynamic> getOrder(String orderId) async {}

  Future<void> pingOrder(String orderId) async {}

  Future<void> escalateOrder(String orderId, {String? reason}) async {}
}
