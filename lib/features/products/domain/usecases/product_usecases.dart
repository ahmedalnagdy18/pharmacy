import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/domain/repositories/products_repository.dart';

class GetProductsUseCase {
  const GetProductsUseCase(this.repository);

  final ProductsRepository repository;

  Future<List<MedicineModel>> call() => repository.getProducts();
}

class SaveProductUseCase {
  const SaveProductUseCase(this.repository);

  final ProductsRepository repository;

  Future<void> call(MedicineModel product) => repository.saveProduct(product);
}

class DeleteProductUseCase {
  const DeleteProductUseCase(this.repository);

  final ProductsRepository repository;

  Future<void> call(String id) => repository.deleteProduct(id);
}
