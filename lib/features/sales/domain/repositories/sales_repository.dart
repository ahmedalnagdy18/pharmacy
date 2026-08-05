import 'package:pharmacy/features/sales/data/model/sale_model.dart';

abstract class SalesRepository {
  Future<List<SaleModel>> getSales();
  Future<List<SaleModel>> getTodaySales();
  Future<List<SaleModel>> getMonthlySales(DateTime month);
  Future<List<SaleModel>> searchSales(String query);
  Future<List<SaleModel>> filterSales(String? saleType);
  Future<void> createDirectSales(List<SaleModel> sales);
  Future<void> createRepresentativeSales(List<SaleModel> sales);
  Future<void> updateInvoice(
    String invoiceId,
    List<SaleModel> sales, {
    required double amountPaid,
  });
  Future<void> recordRepresentativeCollection({
    required String id,
    required String representativeId,
    required String invoiceId,
    required double amount,
    String notes,
  });
  Future<void> cancelInvoice(String invoiceId);
}
