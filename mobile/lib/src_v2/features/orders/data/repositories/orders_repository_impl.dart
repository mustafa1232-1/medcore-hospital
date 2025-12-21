import '../services/orders_api_service.dart';

class OrdersRepositoryImpl {
  final OrdersApiService _api;

  const OrdersRepositoryImpl({OrdersApiService? api})
    : _api = api ?? const OrdersApiService();

  /// كان سابقاً listMyCreatedOrders()
  /// الآن نربطه على listOrders() (الفلاتر نفسها)
  Future<List<Map<String, dynamic>>> listMyCreatedOrders({
    String? q,
    String status = 'ALL',
    String target = 'ALL',
    String priority = 'ALL',
  }) {
    return _api.listOrders(
      q: q,
      status: status,
      target: target,
      priority: priority,
    );
  }

  /// بعض الشاشات قد تستخدم listMyAssignedOrders (إن وجدت عندك)
  /// نربطها أيضاً على listOrders() حالياً (إلى أن نضيف endpoint مخصص)
  Future<List<Map<String, dynamic>>> listMyAssignedOrders({
    String? q,
    String status = 'ALL',
    String target = 'ALL',
    String priority = 'ALL',
  }) {
    return _api.listOrders(
      q: q,
      status: status,
      target: target,
      priority: priority,
    );
  }

  /// كان سابقاً getOrderById()
  Future<Map<String, dynamic>> getOrderById(String orderId) {
    return _api.getOrder(orderId);
  }

  /// كان سابقاً createOrder(...) مع message/priority كـ named params
  /// نخليه يقبل الشكلين حتى لا يكسر أي استدعاء قديم.
  Future<Map<String, dynamic>> createOrder({
    required String patientId,
    required String assigneeUserId,
    String target = 'NURSE',
    String priority = 'NORMAL',
    String? message, // legacy name
    String? notes, // new name
  }) {
    return _api.createOrder(
      patientId: patientId,
      assigneeUserId: assigneeUserId,
      target: target,
      priority: priority,
      notes: (notes ?? message),
    );
  }

  Future<void> ping(String orderId, {String? reason}) {
    return _api.pingOrder(orderId, reason: reason);
  }

  Future<void> escalate(String orderId, {String? reason}) {
    return _api.escalateOrder(orderId, reason: reason);
  }
}
