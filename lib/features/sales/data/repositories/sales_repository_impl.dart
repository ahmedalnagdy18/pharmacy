import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/representative_inventory/data/data_source/representative_inventory_local_data_source.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  const SalesRepositoryImpl({
    required this.salesDataSource,
    required this.productsDataSource,
    required this.inventoryDataSource,
  });

  final SalesLocalDataSource salesDataSource;
  final ProductsLocalDataSource productsDataSource;
  final RepresentativeInventoryLocalDataSource inventoryDataSource;

  @override
  Future<List<SaleModel>> getSales() => salesDataSource.getAll();

  @override
  Future<List<SaleModel>> getTodaySales() async {
    final now = DateTime.now();
    return (await getSales()).where((sale) {
      return sale.date.year == now.year &&
          sale.date.month == now.month &&
          sale.date.day == now.day;
    }).toList();
  }

  @override
  Future<List<SaleModel>> getMonthlySales(DateTime month) async {
    return (await getSales()).where((sale) {
      return sale.date.year == month.year && sale.date.month == month.month;
    }).toList();
  }

  @override
  Future<List<SaleModel>> searchSales(String query) async {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return getSales();
    }
    final products = await productsDataSource.getAll();
    final matchingProductIds = products
        .where(
          (product) =>
              product.name.toLowerCase().contains(normalizedQuery) ||
              product.barcode.toLowerCase().contains(normalizedQuery),
        )
        .map((product) => product.id)
        .toSet();
    return (await getSales())
        .where((sale) => matchingProductIds.contains(sale.productId))
        .toList();
  }

  @override
  Future<List<SaleModel>> filterSales(String? saleType) async {
    if (saleType == null || saleType.isEmpty) {
      return getSales();
    }
    return (await getSales())
        .where((sale) => sale.saleType == saleType)
        .toList();
  }

  @override
  Future<void> createDirectSale(SaleModel sale) async {
    if (sale.quantity <= 0) {
      throw const AppException('Sale quantity must be greater than zero.');
    }
    final product = await productsDataSource.getById(sale.productId);
    if (product == null) {
      throw const AppException('Product was not found.');
    }
    if (product.quantity < sale.quantity) {
      throw const AppException('Not enough warehouse stock.');
    }

    await productsDataSource.save(
      product.copyWith(quantity: product.quantity - sale.quantity),
    );
    await salesDataSource.save(sale.copyWith(saleType: SaleType.direct));
  }

  @override
  Future<void> createRepresentativeSale(SaleModel sale) async {
    if (sale.quantity <= 0) {
      throw const AppException('Sale quantity must be greater than zero.');
    }
    final representativeId = sale.representativeId;
    if (representativeId == null || representativeId.isEmpty) {
      throw const AppException('Representative is required.');
    }

    final inventory = await inventoryDataSource.getByRepresentativeAndProduct(
      representativeId: representativeId,
      productId: sale.productId,
    );
    if (inventory == null) {
      throw const AppException('Representative inventory was not found.');
    }
    if (inventory.remainingQuantity < sale.quantity) {
      throw const AppException('Not enough representative stock.');
    }

    await inventoryDataSource.save(
      inventory.copyWith(quantitySold: inventory.quantitySold + sale.quantity),
    );
    await salesDataSource.save(
      sale.copyWith(saleType: SaleType.representative),
    );
  }
}
