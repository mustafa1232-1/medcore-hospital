import '../entities/order_entity.dart';

class OrdersListQuery {
  final String? admissionId;
  final String? patientId;
  final String? kind; // MEDICATION | LAB | PROCEDURE
  final String?
  status; // CREATED | IN_PROGRESS | PARTIALLY_COMPLETED | COMPLETED | OUT_OF_STOCK | CANCELLED
  final int limit;
  final int offset;

  const OrdersListQuery({
    this.admissionId,
    this.patientId,
    this.kind,
    this.status,
    this.limit = 20,
    this.offset = 0,
  });

  Map<String, dynamic> toQuery() => {
    if (admissionId != null && admissionId!.trim().isNotEmpty)
      'admissionId': admissionId!.trim(),
    if (patientId != null && patientId!.trim().isNotEmpty)
      'patientId': patientId!.trim(),
    if (kind != null && kind!.trim().isNotEmpty) 'kind': kind!.trim(),
    if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
    'limit': limit,
    'offset': offset,
  };
}

abstract class OrdersRepository {
  Future<List<OrderEntity>> listOrders(OrdersListQuery query);

  Future<OrderEntity> getOrderById(String id);

  /// Doctor creates:
  Future<OrderEntity> createMedicationOrder({
    required String admissionId,
    required String medicationName,
    required String dose,
    required String route,
    required String frequency,
    String? duration,
    bool startNow,
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
  });

  Future<OrderEntity> createLabOrder({
    required String admissionId,
    required String testName,
    String priority,
    String specimen,
    String? notes,
  });

  Future<OrderEntity> createProcedureOrder({
    required String admissionId,
    required String procedureName,
    String urgency,
    String? notes,
  });

  /// Doctor cancels:
  Future<OrderEntity> cancelOrder({required String id, String? notes});

  /// Pharmacy actions:
  Future<OrderEntity> pharmacyPrepare({required String orderId, String? notes});
  Future<OrderEntity> pharmacyPartial({
    required String orderId,
    required num preparedQty,
    String? notes,
  });
  Future<OrderEntity> pharmacyOutOfStock({
    required String orderId,
    String? notes,
  });

  /// Patient view:
  Future<List<Map<String, dynamic>>> listPatientMedications({
    int limit,
    int offset,
  });
}
