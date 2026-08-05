import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/domain/repositories/sales_repository.dart';

class GetSalesUseCase {
  const GetSalesUseCase(this.repository);

  final SalesRepository repository;

  Future<List<SaleModel>> call() => repository.getSales();
}

class CreateDirectSaleUseCase {
  const CreateDirectSaleUseCase(this.repository);

  final SalesRepository repository;

  Future<void> call(List<SaleModel> sales) =>
      repository.createDirectSales(sales);
}

class CreateRepresentativeSaleUseCase {
  const CreateRepresentativeSaleUseCase(this.repository);

  final SalesRepository repository;

  Future<void> call(List<SaleModel> sales) =>
      repository.createRepresentativeSales(sales);
}

class UpdateSaleInvoiceUseCase {
  const UpdateSaleInvoiceUseCase(this.repository);

  final SalesRepository repository;

  Future<void> call(
    String invoiceId,
    List<SaleModel> sales, {
    required double amountPaid,
  }) => repository.updateInvoice(
    invoiceId,
    sales,
    amountPaid: amountPaid,
  );
}

class RecordRepresentativeCollectionUseCase {
  const RecordRepresentativeCollectionUseCase(this.repository);

  final SalesRepository repository;

  Future<void> call({
    required String id,
    required String representativeId,
    required String invoiceId,
    required double amount,
    String notes = '',
  }) => repository.recordRepresentativeCollection(
    id: id,
    representativeId: representativeId,
    invoiceId: invoiceId,
    amount: amount,
    notes: notes,
  );
}

class SearchAndFilterSalesUseCase {
  const SearchAndFilterSalesUseCase(this.repository);

  final SalesRepository repository;

  Future<List<SaleModel>> call({
    required String query,
    required String? saleType,
  }) async {
    final sales = query.trim().isEmpty
        ? await repository.filterSales(saleType)
        : await repository.searchSales(query);
    if (saleType == null || saleType.isEmpty) {
      return sales;
    }
    return sales.where((sale) => sale.saleType == saleType).toList();
  }
}

class CancelSaleInvoiceUseCase {
  const CancelSaleInvoiceUseCase(this.repository);

  final SalesRepository repository;

  Future<void> call(String invoiceId) => repository.cancelInvoice(invoiceId);
}
