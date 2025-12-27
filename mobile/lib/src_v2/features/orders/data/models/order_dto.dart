import '../../domain/entities/order_entity.dart';

class OrderDto {
  final Map<String, dynamic> raw;
  OrderDto(this.raw);

  static DateTime? _parseDtOrNull(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    final s = v.toString();
    return DateTime.tryParse(s);
  }

  static DateTime _parseDtOrNow(dynamic v) {
    return _parseDtOrNull(v) ?? DateTime.now();
  }

  static String _normKind(String s) {
    final x = s.trim().toUpperCase();
    if (x == 'MEDICATION' || x == 'LAB' || x == 'PROCEDURE') return x;
    return x.isEmpty ? 'MEDICATION' : x;
  }

  static String _normStatus(String s) {
    final x = s.trim().toUpperCase();

    // ✅ New backend statuses
    const known = {
      'CREATED',
      'IN_PROGRESS',
      'PARTIALLY_COMPLETED',
      'COMPLETED',
      'OUT_OF_STOCK',
      'CANCELLED',
    };
    if (known.contains(x)) return x;

    // ✅ Backward compatibility (older/legacy values)
    if (x == 'PENDING') return 'CREATED';
    if (x == 'STARTED') return 'IN_PROGRESS';

    return x.isEmpty ? 'CREATED' : x;
  }

  static Map<String, dynamic> _mapPayload(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  OrderEntity toEntity() {
    final id = (raw['id'] ?? '').toString();

    // backend new shape:
    // admission_id => admissionId, patient_id => patientId
    final admissionId = (raw['admissionId'] ?? raw['admission_id'] ?? '')
        .toString();
    final patientId = (raw['patientId'] ?? raw['patient_id'] ?? '').toString();

    final kind = _normKind((raw['kind'] ?? '').toString());
    final status = _normStatus((raw['status'] ?? '').toString());

    final payload = _mapPayload(raw['payload']);

    final createdAt = _parseDtOrNow(raw['createdAt'] ?? raw['created_at']);
    final updatedAt = _parseDtOrNull(raw['updatedAt'] ?? raw['updated_at']);
    final cancelledAt = _parseDtOrNull(
      raw['cancelledAt'] ?? raw['cancelled_at'],
    );

    return OrderEntity(
      id: id,
      admissionId: admissionId,
      patientId: patientId,
      kind: kind,
      status: status,
      payload: payload,
      notes: raw['notes']?.toString(),
      createdAt: createdAt,
      updatedAt: updatedAt,
      cancelledAt: cancelledAt,
    );
  }
}
