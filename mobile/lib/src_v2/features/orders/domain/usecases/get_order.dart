import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrderUseCase {
  final OrdersRepository repo;
  const GetOrderUseCase(this.repo);

  Future<OrderEntity> call(String id) => repo.getOrderById(id);
}
