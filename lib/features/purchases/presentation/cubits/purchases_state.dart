import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';

abstract class PurchasesState extends Equatable {
  const PurchasesState();
  @override
  List<Object?> get props => [];
}

class PurchasesInitial extends PurchasesState {
  const PurchasesInitial();
}

class PurchasesLoading extends PurchasesState {
  const PurchasesLoading();
}

class PurchasesLoaded extends PurchasesState {
  const PurchasesLoaded(this.purchases);
  final List<PurchaseModel> purchases;
  @override
  List<Object?> get props => [purchases];
}

class PurchasesError extends PurchasesState {
  const PurchasesError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
