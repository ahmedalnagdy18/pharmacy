import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/purchases/domain/usecases/purchase_usecases.dart';
import 'package:pharmacy/features/purchases/presentation/cubits/purchases_state.dart';
import 'package:uuid/uuid.dart';

class PurchasesCubit extends Cubit<PurchasesState> {
  PurchasesCubit(this.useCases) : super(const PurchasesInitial());
  final PurchaseUseCases useCases;
  final _uuid = const Uuid();
  Future<void> load() async {
    emit(const PurchasesLoading());
    try {
      emit(PurchasesLoaded(await useCases.list()));
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }

  Future<void> create({
    required String supplierId,
    required List<PurchaseLine> lines,
    required double paidAmount,
  }) async {
    try {
      final invoiceId = _uuid.v4();
      await useCases.create(
        lines
            .map(
              (line) => PurchaseModel(
                id: _uuid.v4(),
                supplierId: supplierId,
                productId: line.productId,
                quantity: line.quantity,
                unitCost: line.unitCost,
                total: line.quantity * line.unitCost,
                paidAmount: paidAmount,
                date: DateTime.now(),
                invoiceId: invoiceId,
              ),
            )
            .toList(),
      );
      await load();
    } catch (e) {
      emit(PurchasesError(e.toString()));
    }
  }
}

class PurchaseLine {
  const PurchaseLine({
    required this.productId,
    required this.quantity,
    required this.unitCost,
  });
  final String productId;
  final int quantity;
  final double unitCost;
}
