import 'package:pharmacy/features/dashboard/data/model/dashboard_stats_model.dart';
import 'package:pharmacy/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/domain/repositories/sales_repository.dart';

class ReportsUseCases {
  const ReportsUseCases({
    required this.dashboardRepository,
    required this.salesRepository,
  });

  final DashboardRepository dashboardRepository;
  final SalesRepository salesRepository;

  Future<List<SaleModel>> dailySales(DateTime date) async {
    final sales = await salesRepository.getSales();
    return sales
        .where(
          (sale) =>
              sale.date.year == date.year &&
              sale.date.month == date.month &&
              sale.date.day == date.day,
        )
        .toList();
  }

  Future<List<SaleModel>> monthlySales(DateTime month) {
    return salesRepository.getMonthlySales(month);
  }

  Future<List<MedicineSalesSummary>> topMedicines() async {
    return (await dashboardRepository.getStats()).topSellingMedicines;
  }

  Future<List<RepresentativeSalesSummary>> topRepresentatives() async {
    return (await dashboardRepository.getStats()).topRepresentatives;
  }

  Future<double> inventoryValue() async {
    return (await dashboardRepository.getStats()).inventoryValue;
  }
}
