import 'package:hive/hive.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';

class ProductsLocalDataSource {
  const ProductsLocalDataSource(this.box);

  final Box<MedicineModel> box;

  Future<List<MedicineModel>> getAll() async {
    final products = box.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return products;
  }

  Future<MedicineModel?> getById(String id) async => box.get(id);

  Future<void> save(MedicineModel product) async {
    await box.put(product.id, product);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }
}
