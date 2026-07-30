import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/sales/domain/usecases/sales_usecases.dart';
import 'package:pharmacy/features/sales/presentation/cubits/sales_state.dart';
import 'package:uuid/uuid.dart';

class SalesCubit extends Cubit<SalesState> {
  SalesCubit({
    required this.getSales,
    required this.createDirectSale,
    required this.createRepresentativeSale,
    required this.cancelSaleInvoice,
    required this.searchAndFilterSales,
  }) : super(const SalesInitial());

  final GetSalesUseCase getSales;
  final CreateDirectSaleUseCase createDirectSale;
  final CreateRepresentativeSaleUseCase createRepresentativeSale;
  final CancelSaleInvoiceUseCase cancelSaleInvoice;
  final SearchAndFilterSalesUseCase searchAndFilterSales;
  final _uuid = const Uuid();

  Future<void> load() async {
    emit(const SalesLoading());
    try {
      emit(SalesLoaded(await getSales()));
    } catch (error) {
      emit(SalesError(error.toString()));
    }
  }

  Future<void> searchAndFilter({
    required String query,
    required String? saleType,
  }) async {
    emit(const SalesLoading());
    try {
      emit(
        SalesLoaded(
          await searchAndFilterSales(query: query, saleType: saleType),
        ),
      );
    } catch (error) {
      emit(SalesError(error.toString()));
    }
  }

  Future<void> addDirectSales({
    required List<SaleLine> lines,
    String? customerName,
    String? customerPhone,
    required double amountPaid,
  }) async {
    emit(const SalesLoading());
    try {
      final invoiceId = _uuid.v4();
      await createDirectSale(
        lines
            .map(
              (line) => SaleModel(
                id: _uuid.v4(),
                productId: line.productId,
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                total: line.quantity * line.unitPrice,
                date: DateTime.now(),
                saleType: SaleType.direct,
                representativeId: null,
                invoiceId: invoiceId,
                customerName: customerName,
                customerPhone: customerPhone,
                amountPaid: amountPaid,
              ),
            )
            .toList(),
      );
      emit(SalesLoaded(await getSales()));
    } catch (error) {
      emit(SalesError(error.toString()));
      await load();
    }
  }

  Future<void> addRepresentativeSales({
    required String representativeId,
    required List<SaleLine> lines,
  }) async {
    emit(const SalesLoading());
    try {
      final invoiceId = _uuid.v4();
      await createRepresentativeSale(
        lines
            .map(
              (line) => SaleModel(
                id: _uuid.v4(),
                productId: line.productId,
                quantity: line.quantity,
                unitPrice: line.unitPrice,
                total: line.quantity * line.unitPrice,
                date: DateTime.now(),
                saleType: SaleType.representative,
                representativeId: representativeId,
                invoiceId: invoiceId,
              ),
            )
            .toList(),
      );
      emit(SalesLoaded(await getSales()));
    } catch (error) {
      emit(SalesError(error.toString()));
      await load();
    }
  }

  Future<void> cancelInvoice(String invoiceId) async {
    emit(const SalesLoading());
    try {
      await cancelSaleInvoice(invoiceId);
      emit(SalesLoaded(await getSales()));
    } catch (error) {
      emit(SalesError(error.toString()));
      await load();
    }
  }
}

class SaleLine {
  const SaleLine({
    required this.productId,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final int quantity;
  final double unitPrice;
}
