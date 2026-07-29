import 'package:pharmacy/features/dashboard/data/model/dashboard_stats_model.dart';
import 'package:pharmacy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:pharmacy/features/products/data/data_source/products_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/data_source/representatives_local_data_source.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl({
    required this.productsDataSource,
    required this.representativesDataSource,
    required this.salesDataSource,
  });

  final ProductsLocalDataSource productsDataSource;
  final RepresentativesLocalDataSource representativesDataSource;
  final SalesLocalDataSource salesDataSource;

  @override
  Future<DashboardStatsModel> getStats() async {
    final products = await productsDataSource.getAll();
    final representatives = await representativesDataSource.getAll();
    final sales = await salesDataSource.getAll();
    final now = DateTime.now();

    final totalWarehouseQuantity = products.fold<int>(
      0,
      (sum, product) => sum + product.quantity,
    );
    final inventoryValue = products.fold<double>(
      0,
      (sum, product) => sum + product.quantity * product.purchasePrice,
    );
    final todaySales = sales
        .where(
          (sale) =>
              sale.date.year == now.year &&
              sale.date.month == now.month &&
              sale.date.day == now.day,
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);
    final monthlySales = sales
        .where(
          (sale) => sale.date.year == now.year && sale.date.month == now.month,
        )
        .fold<double>(0, (sum, sale) => sum + sale.total);

    final productById = {for (final product in products) product.id: product};
    final representativeById = {
      for (final representative in representatives)
        representative.id: representative,
    };

    final medicineQuantities = <String, int>{};
    final medicineTotals = <String, double>{};
    final representativeQuantities = <String, int>{};
    final representativeTotals = <String, double>{};

    for (final sale in sales) {
      medicineQuantities.update(
        sale.productId,
        (value) => value + sale.quantity,
        ifAbsent: () => sale.quantity,
      );
      medicineTotals.update(
        sale.productId,
        (value) => value + sale.total,
        ifAbsent: () => sale.total,
      );
      if (sale.saleType == SaleType.representative &&
          sale.representativeId != null) {
        representativeQuantities.update(
          sale.representativeId!,
          (value) => value + sale.quantity,
          ifAbsent: () => sale.quantity,
        );
        representativeTotals.update(
          sale.representativeId!,
          (value) => value + sale.total,
          ifAbsent: () => sale.total,
        );
      }
    }

    final topMedicines =
        medicineQuantities.entries
            .where((entry) => productById.containsKey(entry.key))
            .map(
              (entry) => MedicineSalesSummary(
                product: productById[entry.key]!,
                quantitySold: entry.value,
                totalSales: medicineTotals[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

    final topRepresentatives =
        representativeQuantities.entries
            .where((entry) => representativeById.containsKey(entry.key))
            .map(
              (entry) => RepresentativeSalesSummary(
                representative: representativeById[entry.key]!,
                quantitySold: entry.value,
                totalSales: representativeTotals[entry.key] ?? 0,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

    final lowStockProducts =
        products.where((product) => product.quantity <= 5).toList()
          ..sort((a, b) => a.quantity.compareTo(b.quantity));

    return DashboardStatsModel(
      totalProducts: products.length,
      totalWarehouseQuantity: totalWarehouseQuantity,
      inventoryValue: inventoryValue,
      todaySales: todaySales,
      monthlySales: monthlySales,
      lowStockProducts: lowStockProducts,
      topSellingMedicines: topMedicines.take(5).toList(),
      topRepresentatives: topRepresentatives.take(5).toList(),
    );
  }
}
