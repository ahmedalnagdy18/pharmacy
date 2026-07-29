import 'package:hive/hive.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';

class SalesLocalDataSource {
  const SalesLocalDataSource(this.box);

  final Box<SaleModel> box;

  Future<List<SaleModel>> getAll() async {
    final sales = box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sales;
  }

  Future<void> save(SaleModel sale) async {
    await box.put(sale.id, sale);
  }
}
