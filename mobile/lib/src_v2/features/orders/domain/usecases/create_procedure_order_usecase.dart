import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class CreateProcedureOrderUseCase {
  final OrdersRepository repo;
  const CreateProcedureOrderUseCase(this.repo);

  Future<OrderEntity> call({
    required String admissionId,
    required String procedureName,
    String urgency = 'NORMAL',
    String? notes,
  }) {
    return repo.createProcedureOrder(
      admissionId: admissionId,
      procedureName: procedureName,
      urgency: urgency,
      notes: notes,
    );
  }
}
