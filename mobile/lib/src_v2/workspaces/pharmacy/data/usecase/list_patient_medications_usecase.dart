import 'package:mobile/src_v2/features/orders/domain/repositories/orders_repository.dart';

class ListPatientMedicationsUseCase {
  final OrdersRepository repo;
  const ListPatientMedicationsUseCase(this.repo);

  Future<List<Map<String, dynamic>>> call({int limit = 50, int offset = 0}) {
    return repo.listPatientMedications(limit: limit, offset: offset);
  }
}
