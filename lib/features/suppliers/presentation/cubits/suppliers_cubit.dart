import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';
import 'package:pharmacy/features/suppliers/domain/usecases/supplier_usecases.dart';
import 'package:pharmacy/features/suppliers/presentation/cubits/suppliers_state.dart';
import 'package:uuid/uuid.dart';

class SuppliersCubit extends Cubit<SuppliersState> {
  SuppliersCubit(this.useCases) : super(const SuppliersInitial());
  final SupplierUseCases useCases;
  final _uuid = const Uuid();
  Future<void> load() async {
    emit(const SuppliersLoading());
    try {
      emit(
        SuppliersLoaded(
          await useCases.suppliers(),
          await useCases.debts(),
          await useCases.payments(),
        ),
      );
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> save({
    String? id,
    required String name,
    String phone = '',
    String company = '',
    String notes = '',
  }) async {
    try {
      await useCases.save(
        SupplierModel(
          id: id ?? _uuid.v4(),
          name: name.trim(),
          phone: phone.trim(),
          company: company.trim(),
          notes: notes.trim(),
        ),
      );
      await load();
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    try {
      await useCases.delete(id);
      await load();
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }

  Future<void> recordPayment({
    required String supplierId,
    required String debtId,
    required double amount,
    String notes = '',
  }) async {
    try {
      await useCases.payment(
        SupplierPaymentModel(
          id: _uuid.v4(),
          supplierId: supplierId,
          debtId: debtId,
          amount: amount,
          date: DateTime.now(),
          notes: notes.trim(),
        ),
      );
      await load();
    } catch (e) {
      emit(SuppliersError(e.toString()));
    }
  }
}
