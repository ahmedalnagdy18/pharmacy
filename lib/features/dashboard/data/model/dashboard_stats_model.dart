import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';

class MedicineSalesSummary extends Equatable {
  const MedicineSalesSummary({
    required this.product,
    required this.quantitySold,
    required this.totalSales,
  });

  final MedicineModel product;
  final int quantitySold;
  final double totalSales;

  @override
  List<Object?> get props => [product, quantitySold, totalSales];
}

class RepresentativeSalesSummary extends Equatable {
  const RepresentativeSalesSummary({
    required this.representative,
    required this.quantitySold,
    required this.totalSales,
  });

  final RepresentativeModel representative;
  final int quantitySold;
  final double totalSales;

  @override
  List<Object?> get props => [representative, quantitySold, totalSales];
}

class DashboardStatsModel extends Equatable {
  const DashboardStatsModel({
    required this.totalProducts,
    required this.totalWarehouseQuantity,
    required this.inventoryValue,
    required this.todaySales,
    required this.monthlySales,
    required this.lowStockProducts,
    required this.topSellingMedicines,
    required this.topRepresentatives,
    required this.outstandingCustomerDebts,
    required this.outstandingSupplierDebts,
    required this.todayCollections,
    required this.todayPayments,
    required this.expenses,
    required this.netProfit,
    required this.operatingCashFlow,
  });

  final int totalProducts;
  final int totalWarehouseQuantity;
  final double inventoryValue;
  final double todaySales;
  final double monthlySales;
  final List<MedicineModel> lowStockProducts;
  final List<MedicineSalesSummary> topSellingMedicines;
  final List<RepresentativeSalesSummary> topRepresentatives;
  final double outstandingCustomerDebts;
  final double outstandingSupplierDebts;
  final double todayCollections;
  final double todayPayments;
  final double expenses;
  final double netProfit;
  final double operatingCashFlow;

  @override
  List<Object?> get props => [
    totalProducts,
    totalWarehouseQuantity,
    inventoryValue,
    todaySales,
    monthlySales,
    lowStockProducts,
    topSellingMedicines,
    topRepresentatives,
    outstandingCustomerDebts,
    outstandingSupplierDebts,
    todayCollections,
    todayPayments,
    expenses,
    netProfit,
    operatingCashFlow,
  ];
}
