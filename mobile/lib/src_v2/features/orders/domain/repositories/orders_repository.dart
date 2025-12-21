import '../entities/order_entity.dart';

class OrdersListQuery {
  final String? q;
  final String? status; // ALL|PENDING|STARTED|COMPLETED|CANCELLED
  final String? priority; // ALL|ROUTINE|URGENT|STAT
  final int limit;
  final int offset;

  const OrdersListQuery({
    this.q,
    this.status,
    this.priority,
    this.limit = 20,
    this.offset = 0,
  });

  Map<String, dynamic> toQuery() => {
    if (q != null && q!.trim().isNotEmpty) 'q': q!.trim(),
    if (status != null && status != 'ALL') 'status': status,
    if (priority != null && priority != 'ALL') 'priority': priority,
    'limit': limit,
    'offset': offset,
  };
}

abstract class OrdersRepository {
  Future<List<OrderEntity>> listMyCreatedOrders(OrdersListQuery query);

  Future<OrderEntity> getOrderById(String id);

  Future<OrderEntity> createOrder({
    required String targetRole, // NURSE/LAB/PHARMACY
    required String? assignedToUserId, // nullable إذا role عام
    required String patientId,
    required String? admissionId, // اختياري
    required String priority, // ROUTINE/URGENT/STAT
    required String notes,
  });

  Future<void> pingOrder(String orderId, {String? message});

  Future<void> escalateOrder(
    String orderId, {
    required String priority,
    String? reason,
  });
}
