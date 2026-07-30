import 'package:hive/hive.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';

class PurchasesLocalDataSource {
  const PurchasesLocalDataSource(this.box);
  final Box<PurchaseModel> box;
  Future<List<PurchaseModel>> getAll() async =>
      box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  Future<void> save(PurchaseModel x) => box.put(x.id, x);
}
