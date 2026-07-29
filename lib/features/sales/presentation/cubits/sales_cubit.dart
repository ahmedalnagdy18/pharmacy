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
    required this.searchAndFilterSales,
  }) : super(const SalesInitial());

  final GetSalesUseCase getSales;
  final CreateDirectSaleUseCase createDirectSale;
  final CreateRepresentativeSaleUseCase createRepresentativeSale;
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

  Future<void> addDirectSale({
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    emit(const SalesLoading());
    try {
      await createDirectSale(
        SaleModel(
          id: _uuid.v4(),
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
          total: quantity * unitPrice,
          date: DateTime.now(),
          saleType: SaleType.direct,
          representativeId: null,
        ),
      );
      emit(SalesLoaded(await getSales()));
    } catch (error) {
      emit(SalesError(error.toString()));
      await load();
    }
  }

  Future<void> addRepresentativeSale({
    required String representativeId,
    required String productId,
    required int quantity,
    required double unitPrice,
  }) async {
    emit(const SalesLoading());
    try {
      await createRepresentativeSale(
        SaleModel(
          id: _uuid.v4(),
          productId: productId,
          quantity: quantity,
          unitPrice: unitPrice,
          total: quantity * unitPrice,
          date: DateTime.now(),
          saleType: SaleType.representative,
          representativeId: representativeId,
        ),
      );
      emit(SalesLoaded(await getSales()));
    } catch (error) {
      emit(SalesError(error.toString()));
      await load();
    }
  }
}
