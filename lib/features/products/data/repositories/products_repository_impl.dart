import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/products/domain/repositories/products_repository.dart';
import 'package:pharmacy/features/purchases/data/data_source/purchases_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';

class ProductsRepositoryImpl implements ProductsRepository {
  const ProductsRepositoryImpl(
    this.localDataSource, {
    required this.salesDataSource,
    required this.purchasesDataSource,
    required this.inventoryDataSource,
  });

  final ProductsLocalDataSource localDataSource;
  final SalesLocalDataSource salesDataSource;
  final PurchasesLocalDataSource purchasesDataSource;
  final RepresentativeInventoryLocalDataSource inventoryDataSource;

  @override
  Future<List<MedicineModel>> getProducts() => localDataSource.getAll();

  @override
  Future<MedicineModel?> getProductById(String id) =>
      localDataSource.getById(id);

  @override
  Future<void> saveProduct(MedicineModel product) async {
    if (product.name.trim().isEmpty) {
      throw const AppException('Product name is required.');
    }
    if (product.quantity < 0) {
      throw const AppException('Quantity cannot be negative.');
    }
    if (!product.purchasePrice.isFinite ||
        !product.sellingPrice.isFinite ||
        product.purchasePrice < 0 ||
        product.sellingPrice < 0) {
      throw const AppException('Prices cannot be negative.');
    }
    final normalizedBarcode = product.barcode.trim().toLowerCase();
    if (normalizedBarcode.isNotEmpty) {
      final duplicate = (await localDataSource.getAll()).any(
        (item) =>
            item.id != product.id &&
            item.barcode.trim().toLowerCase() == normalizedBarcode,
      );
      if (duplicate) {
        throw const AppException('A product already uses this barcode.');
      }
    }
    await localDataSource.save(product);
  }

  @override
  Future<void> deleteProduct(String id) async {
    final hasSales = (await salesDataSource.getAll()).any(
      (item) => item.productId == id,
    );
    final hasPurchases = (await purchasesDataSource.getAll()).any(
      (item) => item.productId == id,
    );
    final hasInventory = (await inventoryDataSource.getAll()).any(
      (item) => item.productId == id,
    );
    if (hasSales || hasPurchases || hasInventory) {
      throw const AppException(
        'Products with sales, purchases, or representative inventory cannot be deleted.',
      );
    }
    await localDataSource.delete(id);
  }

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
