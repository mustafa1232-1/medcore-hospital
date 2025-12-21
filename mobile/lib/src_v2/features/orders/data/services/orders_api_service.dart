import 'package:dio/dio.dart';
import 'package:mobile/src/core/api/api_client.dart';

class OrdersApiService {
  const OrdersApiService();

  Dio get _dio => ApiClient.dio;

  Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return v.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  /// Accepts:
  /// - List<Map>
  /// - {items:[...]} or {data:[...]} or {results:[...]}
  /// - {ok:true, items:[...]}
  /// - {data:{items:[...]}} (some APIs)
  List<Map<String, dynamic>> _asListOfMap(dynamic v) {
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    if (v is Map) {
      final m = v.cast<String, dynamic>();

      dynamic items = m['items'] ?? m['data'] ?? m['results'];

      // sometimes: { data: { items: [...] } }
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
    return <Map<String, dynamic>>[];
  }

  String? _cleanFilter(String v) {
    final s = v.trim();
    if (s.isEmpty) return null;
    if (s.toUpperCase() == 'ALL') return null;
    return s;
  }

  Future<List<Map<String, dynamic>>> listOrders({
    String? q,
    String status = 'ALL',
    String target = 'ALL',
    String priority = 'ALL',
  }) async {
    final res = await _dio.get(
      '/api/orders',
      queryParameters: {
        if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        if (_cleanFilter(status) != null) 'status': _cleanFilter(status),
        if (_cleanFilter(target) != null) 'target': _cleanFilter(target),
        if (_cleanFilter(priority) != null) 'priority': _cleanFilter(priority),
      },
    );
    return _asListOfMap(res.data);
  }

  Future<Map<String, dynamic>> getOrder(String orderId) async {
    final res = await _dio.get('/api/orders/$orderId');
    return _asMap(res.data);
  }

  Future<Map<String, dynamic>> createOrder({
    required String patientId,
    required String assigneeUserId,
    required String target,
    required String priority,
    String? notes,
  }) async {
    final res = await _dio.post(
      '/api/orders',
      data: {
        'patientId': patientId,
        'assigneeUserId': assigneeUserId,
        'target': target,
        'priority': priority,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
    return _asMap(res.data);
  }

  Future<void> pingOrder(String orderId, {String? reason}) async {
    await _dio.post(
      '/api/orders/$orderId/ping',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<void> escalateOrder(String orderId, {String? reason}) async {
    await _dio.post(
      '/api/orders/$orderId/escalate',
      data: {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> lookupPatients({
    String q = '',
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/api/lookups/patients',
      queryParameters: {'q': q, 'limit': limit},
    );
    return _asListOfMap(res.data);
  }

  Future<List<Map<String, dynamic>>> lookupStaff({
    required String role, // NURSE/LAB/PHARMACY
    String q = '',
    int limit = 20,
  }) async {
    final res = await _dio.get(
      '/api/lookups/staff',
      queryParameters: {'role': role, 'q': q, 'limit': limit},
    );
    return _asListOfMap(res.data);
  }

  Future<List<Map<String, dynamic>>> lookupDepartments({
    String q = '',
    int limit = 100,
  }) async {
    final res = await _dio.get(
      '/api/lookups/departments',
      queryParameters: {'q': q, 'limit': limit},
    );
    return _asListOfMap(res.data);
  }
}
