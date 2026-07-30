import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/purchases/domain/repositories/purchases_repository.dart';

class PurchaseUseCases {
  const PurchaseUseCases(this.repository);
  final PurchasesRepository repository;
  Future<List<PurchaseModel>> list() => repository.purchases();
  Future<void> create(List<PurchaseModel> purchases) =>
      repository.create(purchases);
}
