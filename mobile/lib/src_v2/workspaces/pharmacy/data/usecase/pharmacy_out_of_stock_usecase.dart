import 'package:mobile/src_v2/features/orders/domain/entities/order_entity.dart';
import 'package:mobile/src_v2/features/orders/domain/repositories/orders_repository.dart';

class PharmacyOutOfStockUseCase {
  final OrdersRepository repo;
  const PharmacyOutOfStockUseCase(this.repo);

  Future<OrderEntity> call(String orderId, {String? notes}) {
    return repo.pharmacyOutOfStock(orderId: orderId, notes: notes);
  }
}
