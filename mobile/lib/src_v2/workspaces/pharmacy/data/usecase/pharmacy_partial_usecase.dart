import 'package:mobile/src_v2/features/orders/domain/entities/order_entity.dart';
import 'package:mobile/src_v2/features/orders/domain/repositories/orders_repository.dart';

class PharmacyPartialUseCase {
  final OrdersRepository repo;
  const PharmacyPartialUseCase(this.repo);

  Future<OrderEntity> call(
    String orderId, {
    required num preparedQty,
    String? notes,
  }) {
    return repo.pharmacyPartial(
      orderId: orderId,
      preparedQty: preparedQty,
      notes: notes,
    );
  }
}
