import 'package:pharmacy/features/products/data/model/medicine_model.dart';

abstract class ProductsRepository {
  Future<List<MedicineModel>> getProducts();
  Future<MedicineModel?> getProductById(String id);
  Future<void> saveProduct(MedicineModel product);
  Future<void> deleteProduct(String id);
  Future<void> decreaseWarehouseStock(String productId, int quantity);
  Future<void> increaseWarehouseStock(String productId, int quantity);
}
