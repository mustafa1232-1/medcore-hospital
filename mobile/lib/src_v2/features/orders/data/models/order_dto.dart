import '../../domain/entities/order_entity.dart';

class OrderDto {
  final Map<String, dynamic> raw;
  OrderDto(this.raw);

  OrderEntity toEntity() {
    DateTime parseDt(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      return DateTime.tryParse(v.toString()) ?? DateTime.now();
    }

    return OrderEntity(
      id: (raw['id'] ?? '').toString(),
      code: (raw['code'] ?? raw['orderCode'] ?? 'ORD').toString(),
      status: (raw['status'] ?? 'PENDING').toString(),
      priority: (raw['priority'] ?? 'ROUTINE').toString(),
      notes: raw['notes']?.toString(),

      patientName: raw['patientName']?.toString(),
      roomLabel: raw['roomLabel']?.toString(),

      createdByName: raw['createdByName']?.toString(),
      assignedToName: raw['assignedToName']?.toString(),
      assignedToRole: raw['assignedToRole']?.toString(),

      createdAt: parseDt(raw['createdAt'] ?? raw['created_at']),
      updatedAt: raw['updatedAt'] != null || raw['updated_at'] != null
          ? parseDt(raw['updatedAt'] ?? raw['updated_at'])
          : null,
    );
  }
}
