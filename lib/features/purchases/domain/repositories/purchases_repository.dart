import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';

abstract class PurchasesRepository {
  Future<List<PurchaseModel>> purchases();
  Future<void> create(List<PurchaseModel> purchases);
}
