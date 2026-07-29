import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/domain/repositories/products_repository.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(this.localDataSource);

  final ProductsLocalDataSource localDataSource;

  @override
  Future<List<MedicineModel>> getProducts() => localDataSource.getAll();

  @override
  Future<MedicineModel?> getProductById(String id) =>
      localDataSource.getById(id);

  @override
  Future<void> saveProduct(MedicineModel product) {
    if (product.name.trim().isEmpty) {
      throw const AppException('Product name is required.');
    }
    if (product.quantity < 0) {
      throw const AppException('Quantity cannot be negative.');
    }
    if (product.purchasePrice < 0 || product.sellingPrice < 0) {
      throw const AppException('Prices cannot be negative.');
    }
    return localDataSource.save(product);
  }

  @override
  Future<void> deleteProduct(String id) => localDataSource.delete(id);

  @override
  Future<void> decreaseWarehouseStock(String productId, int quantity) async {
    if (quantity <= 0) {
      throw const AppException('Quantity must be greater than zero.');
    }
    final product = await localDataSource.getById(productId);
    if (product == null) {
      throw const AppException('Product was not found.');
    }
    if (product.quantity < quantity) {
      throw const AppException('Not enough warehouse stock.');
    }
    await localDataSource.save(
      product.copyWith(quantity: product.quantity - quantity),
    );
  }

  @override
  Future<void> increaseWarehouseStock(String productId, int quantity) async {
    if (quantity <= 0) {
      throw const AppException('Quantity must be greater than zero.');
    }
    final product = await localDataSource.getById(productId);
    if (product == null) {
      throw const AppException('Product was not found.');
    }
    await localDataSource.save(
      product.copyWith(quantity: product.quantity + quantity),
    );
  }
}
