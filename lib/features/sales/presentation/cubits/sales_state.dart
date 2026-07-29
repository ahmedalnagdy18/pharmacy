import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';

abstract class SalesState extends Equatable {
  const SalesState();

  @override
  List<Object?> get props => [];
}

class SalesInitial extends SalesState {
  const SalesInitial();
}

class SalesLoading extends SalesState {
  const SalesLoading();
}

class SalesLoaded extends SalesState {
  const SalesLoaded(this.sales);

  final List<SaleModel> sales;

  @override
  List<Object?> get props => [sales];
}

class SalesError extends SalesState {
  const SalesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
