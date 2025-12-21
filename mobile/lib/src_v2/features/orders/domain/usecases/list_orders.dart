import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class ListOrdersUseCase {
  final OrdersRepository repo;
  const ListOrdersUseCase(this.repo);

  Future<List<OrderEntity>> call(OrdersListQuery query) {
    return repo.listMyCreatedOrders(query);
  }
}
