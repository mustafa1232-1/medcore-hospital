import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../models/order_dto.dart';
import '../services/orders_api_service.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersApiService _api;
  const OrdersRepositoryImpl({OrdersApiService? api})
    : _api = api ?? const OrdersApiService();

  List<Map<String, dynamic>> _pickItems(Map<String, dynamic> raw) {
    final items = raw['items'];
    if (items is List) return items.cast<Map<String, dynamic>>();
    final data = raw['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const <Map<String, dynamic>>[];
  }

  Map<String, dynamic> _pickOrderObject(Map<String, dynamic> raw) {
    // endpoints vary:
    // list => {items:[...]}
    // get => {data:{...}}
    // create => {data:{order:{...}, tasks:[...]}} OR {data:{...}} depending on your implementation
    final data = raw['data'];
    if (data is Map) {
      final d = data.cast<String, dynamic>();
      final order = d['order'];
      if (order is Map) return order.cast<String, dynamic>();
      return d;
    }
    final order = raw['order'];
    if (order is Map) return order.cast<String, dynamic>();
    return raw;
  }

  @override
  Future<List<OrderEntity>> listOrders(OrdersListQuery query) async {
    final raw = await _api.listOrders(
      admissionId: query.admissionId,
      patientId: query.patientId,
      kind: query.kind,
      status: query.status,
      limit: query.limit,
      offset: query.offset,
    );

    final items = _pickItems(raw);
    return items.map((m) => OrderDto(m).toEntity()).toList();
  }

  @override
  Future<OrderEntity> getOrderById(String id) async {
    final raw = await _api.getOrderById(id: id);
    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> createMedicationOrder({
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
    final raw = await _api.createMedicationOrder(
      admissionId: admissionId,
      medicationName: medicationName,
      dose: dose,
      route: route,
      frequency: frequency,
      duration: duration,
      startNow: startNow,
      drugId: drugId,
      requestedQty: requestedQty,
      patientInstructionsAr: patientInstructionsAr,
      patientInstructionsEn: patientInstructionsEn,
      dosageText: dosageText,
      frequencyText: frequencyText,
      durationText: durationText,
      withFood: withFood,
      warningsText: warningsText,
      notes: notes,
    );

    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> createLabOrder({
    required String admissionId,
    required String testName,
    String priority = 'ROUTINE',
    String specimen = 'BLOOD',
    String? notes,
  }) async {
    final raw = await _api.createLabOrder(
      admissionId: admissionId,
      testName: testName,
      priority: priority,
      specimen: specimen,
      notes: notes,
    );

    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> createProcedureOrder({
    required String admissionId,
    required String procedureName,
    String urgency = 'NORMAL',
    String? notes,
  }) async {
    final raw = await _api.createProcedureOrder(
      admissionId: admissionId,
      procedureName: procedureName,
      urgency: urgency,
      notes: notes,
    );

    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> cancelOrder({required String id, String? notes}) async {
    final raw = await _api.cancelOrder(id: id, notes: notes);
    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> pharmacyPrepare({
    required String orderId,
    String? notes,
  }) async {
    final raw = await _api.pharmacyPrepare(orderId: orderId, notes: notes);
    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> pharmacyPartial({
    required String orderId,
    required num preparedQty,
    String? notes,
  }) async {
    final raw = await _api.pharmacyPartial(
      orderId: orderId,
      preparedQty: preparedQty,
      notes: notes,
    );
    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<OrderEntity> pharmacyOutOfStock({
    required String orderId,
    String? notes,
  }) async {
    final raw = await _api.pharmacyOutOfStock(orderId: orderId, notes: notes);
    final picked = _pickOrderObject(raw);
    return OrderDto(picked).toEntity();
  }

  @override
  Future<List<Map<String, dynamic>>> listPatientMedications({
    int limit = 50,
    int offset = 0,
  }) async {
    final raw = await _api.listPatientMedications(limit: limit, offset: offset);
    final items = _pickItems(raw);
    return items;
  }
}
