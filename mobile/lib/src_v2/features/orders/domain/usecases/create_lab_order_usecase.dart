import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class CreateLabOrderUseCase {
  final OrdersRepository repo;
  const CreateLabOrderUseCase(this.repo);

  Future<OrderEntity> call({
    required String admissionId,
    required String testName,
    String priority = 'ROUTINE',
    String specimen = 'BLOOD',
    String? notes,
  }) {
    return repo.createLabOrder(
      admissionId: admissionId,
      testName: testName,
      priority: priority,
      specimen: specimen,
      notes: notes,
    );
  }
}
