import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';

abstract class CustomersState extends Equatable {
  const CustomersState();
  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState {
  const CustomersInitial();
}

class CustomersLoading extends CustomersState {
  const CustomersLoading();
}

class CustomersLoaded extends CustomersState {
  const CustomersLoaded(this.customers, this.debts, this.payments);
  final List<CustomerModel> customers;
  final List<CustomerDebtModel> debts;
  final List<CustomerPaymentModel> payments;
  @override
  List<Object?> get props => [customers, debts, payments];
}

class CustomersError extends CustomersState {
  const CustomersError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
