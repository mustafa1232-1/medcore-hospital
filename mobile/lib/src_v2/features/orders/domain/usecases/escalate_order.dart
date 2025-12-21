import '../repositories/orders_repository.dart';

class EscalateOrderUseCase {
  final OrdersRepository repo;
  const EscalateOrderUseCase(this.repo);

  Future<void> call(
    String orderId, {
    required String priority,
    String? reason,
  }) {
    return repo.escalateOrder(orderId, priority: priority, reason: reason);
  }
}
