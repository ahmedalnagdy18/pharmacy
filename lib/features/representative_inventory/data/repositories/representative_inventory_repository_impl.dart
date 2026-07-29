import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representative_inventory/domain/repositories/representative_inventory_repository.dart';

class RepresentativeInventoryRepositoryImpl
    implements RepresentativeInventoryRepository {
  const RepresentativeInventoryRepositoryImpl({
    required this.inventoryDataSource,
    required this.productsDataSource,
  });

  final RepresentativeInventoryLocalDataSource inventoryDataSource;
  final ProductsLocalDataSource productsDataSource;

  @override
  Future<List<RepresentativeInventoryModel>> getInventory() {
    return inventoryDataSource.getAll();
  }

  @override
  Future<List<RepresentativeInventoryModel>> getRepresentativeInventory(
    String representativeId,
  ) {
    return inventoryDataSource.getByRepresentative(representativeId);
  }

  @override
  Future<void> assignInventory({
    required String id,
    required String representativeId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw const AppException('Assigned quantity must be greater than zero.');
    }
    final product = await productsDataSource.getById(productId);
    if (product == null) {
      throw const AppException('Product was not found.');
    }
    if (product.quantity < quantity) {
      throw const AppException('Cannot assign more than warehouse stock.');
    }

    await productsDataSource.save(
      product.copyWith(quantity: product.quantity - quantity),
    );

    final existing = await inventoryDataSource.getByRepresentativeAndProduct(
      representativeId: representativeId,
      productId: productId,
    );

    if (existing == null) {
      await inventoryDataSource.save(
        RepresentativeInventoryModel(
          id: id,
          representativeId: representativeId,
          productId: productId,
          quantityAssigned: quantity,
          quantitySold: 0,
        ),
      );
      return;
    }

    await inventoryDataSource.save(
      existing.copyWith(
        quantityAssigned: existing.quantityAssigned + quantity,
      ),
    );
  }

  @override
  Future<void> recordSoldQuantity({
    required String representativeId,
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw const AppException('Sale quantity must be greater than zero.');
    }
    final inventory = await inventoryDataSource.getByRepresentativeAndProduct(
      representativeId: representativeId,
      productId: productId,
    );
    if (inventory == null) {
      throw const AppException('Representative inventory was not found.');
    }
    if (inventory.remainingQuantity < quantity) {
      throw const AppException('Not enough representative stock.');
    }
    await inventoryDataSource.save(
      inventory.copyWith(quantitySold: inventory.quantitySold + quantity),
    );
  }
}
