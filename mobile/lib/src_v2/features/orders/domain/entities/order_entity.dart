enum OrderStatus { pending, started, completed, cancelled }

enum OrderPriority { routine, urgent, stat }

class OrderEntity {
  final String id;
  final String code;

  final String status; // نتركها String لتوافق backend الحالي بسهولة
  final String priority; // كذلك

  final String? notes;

  final String? patientName;
  final String? roomLabel; // مثال: ER / R-01 / B-02

  final String? createdByName;
  final String? assignedToName;
  final String? assignedToRole;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const OrderEntity({
    required this.id,
    required this.code,
    required this.status,
    required this.priority,
    required this.createdAt,
    this.updatedAt,
    this.notes,
    this.patientName,
    this.roomLabel,
    this.createdByName,
    this.assignedToName,
    this.assignedToRole,
  });
}
