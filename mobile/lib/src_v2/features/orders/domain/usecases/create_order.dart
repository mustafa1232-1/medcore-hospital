import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUseCase {
  final OrdersRepository repo;
  const CreateOrderUseCase(this.repo);

  Future<OrderEntity> call({
    required String targetRole,
    required String? assignedToUserId,
    required String patientId,
    required String? admissionId,
    required String priority,
    required String notes,
  }) {
    return repo.createOrder(
      targetRole: targetRole,
      assignedToUserId: assignedToUserId,
      patientId: patientId,
      admissionId: admissionId,
      priority: priority,
      notes: notes,
    );
  }
}
