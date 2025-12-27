import '../../../../features/orders/domain/entities/order_entity.dart';
import '../../../../features/orders/domain/repositories/orders_repository.dart';

class PharmacyPrepareUseCase {
  final OrdersRepository repo;
  const PharmacyPrepareUseCase(this.repo);

  Future<OrderEntity> call(String orderId, {String? notes}) {
    return repo.pharmacyPrepare(orderId: orderId, notes: notes);
  }
}
