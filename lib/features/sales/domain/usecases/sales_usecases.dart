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

  Future<void> call(SaleModel sale) => repository.createDirectSale(sale);
}

class CreateRepresentativeSaleUseCase {
  const CreateRepresentativeSaleUseCase(this.repository);

  final SalesRepository repository;

  Future<void> call(SaleModel sale) =>
      repository.createRepresentativeSale(sale);
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
