import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/domain/usecases/customer_usecases.dart';
import 'package:pharmacy/features/customers/presentation/cubits/customers_state.dart';
import 'package:uuid/uuid.dart';

class CustomersCubit extends Cubit<CustomersState> {
  CustomersCubit(this.useCases) : super(const CustomersInitial());
  final CustomerUseCases useCases;
  final _uuid = const Uuid();
  Future<void> load() async {
    emit(const CustomersLoading());
    try {
      emit(
        CustomersLoaded(
          await useCases.customers(),
          await useCases.debts(),
          await useCases.payments(),
        ),
      );
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> save({
    String? id,
    required String name,
    required String phone,
    String address = '',
    String notes = '',
    double openingDebt = 0,
  }) async {
    try {
      final customerId = id ?? _uuid.v4();
      await useCases.save(
        CustomerModel(
          id: customerId,
          name: name.trim(),
          phone: phone.trim(),
          address: address.trim(),
          notes: notes.trim(),
          createdAt: DateTime.now(),
        ),
      );
      if (id == null && openingDebt > 0) {
        final now = DateTime.now();
        await useCases.addDebt(CustomerDebtModel(id: _uuid.v4(), customerId: customerId, invoiceId: 'opening-${_uuid.v4()}', invoiceTotal: openingDebt, paidAmount: 0, remainingAmount: openingDebt, status: DebtStatus.pending, createdAt: now, updatedAt: now));
      }
      await load();
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> remove(String id) async {
    try {
      await useCases.delete(id);
      await load();
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> recordPayment({
    required String customerId,
    required String debtId,
    required double amount,
    String notes = '',
  }) async {
    try {
      await useCases.payment(
        CustomerPaymentModel(
          id: _uuid.v4(),
          customerId: customerId,
          debtId: debtId,
          amount: amount,
          date: DateTime.now(),
          notes: notes.trim(),
        ),
      );
      await load();
    } catch (e) {
      emit(CustomersError(e.toString()));
    }
  }

  Future<void> addDebt({required String customerId, required double amount}) async {
    try {
      final now = DateTime.now();
      await useCases.addDebt(CustomerDebtModel(id: _uuid.v4(), customerId: customerId, invoiceId: 'opening-${_uuid.v4()}', invoiceTotal: amount, paidAmount: 0, remainingAmount: amount, status: DebtStatus.pending, createdAt: now, updatedAt: now));
      await load();
    } catch (e) { emit(CustomersError(e.toString())); }
  }
}
