import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';

abstract class SuppliersState extends Equatable {
  const SuppliersState();
  @override
  List<Object?> get props => [];
}

class SuppliersInitial extends SuppliersState {
  const SuppliersInitial();
}

class SuppliersLoading extends SuppliersState {
  const SuppliersLoading();
}

class SuppliersLoaded extends SuppliersState {
  const SuppliersLoaded(this.suppliers, this.debts, this.payments);
  final List<SupplierModel> suppliers;
  final List<SupplierDebtModel> debts;
  final List<SupplierPaymentModel> payments;
  @override
  List<Object?> get props => [suppliers, debts, payments];
}

class SuppliersError extends SuppliersState {
  const SuppliersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
