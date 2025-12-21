import '../repositories/orders_repository.dart';

class PingOrderUseCase {
  final OrdersRepository repo;
  const PingOrderUseCase(this.repo);

  Future<void> call(String orderId, {String? message}) {
    return repo.pingOrder(orderId, message: message);
  }
}
