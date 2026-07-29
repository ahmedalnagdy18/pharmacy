import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representative_inventory/domain/repositories/representative_inventory_repository.dart';

class GetRepresentativeInventoryUseCase {
  const GetRepresentativeInventoryUseCase(this.repository);

  final RepresentativeInventoryRepository repository;

  Future<List<RepresentativeInventoryModel>> call() =>
      repository.getInventory();
}

class AssignRepresentativeInventoryUseCase {
  const AssignRepresentativeInventoryUseCase(this.repository);

  final RepresentativeInventoryRepository repository;

  Future<void> call({
    required String id,
    required String representativeId,
    required String productId,
    required int quantity,
  }) {
    return repository.assignInventory(
      id: id,
      representativeId: representativeId,
      productId: productId,
      quantity: quantity,
    );
  }
}
