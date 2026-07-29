import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';

abstract class RepresentativeInventoryState extends Equatable {
  const RepresentativeInventoryState();

  @override
  List<Object?> get props => [];
}

class RepresentativeInventoryInitial extends RepresentativeInventoryState {
  const RepresentativeInventoryInitial();
}

class RepresentativeInventoryLoading extends RepresentativeInventoryState {
  const RepresentativeInventoryLoading();
}

class RepresentativeInventoryLoaded extends RepresentativeInventoryState {
  const RepresentativeInventoryLoaded(this.inventory);

  final List<RepresentativeInventoryModel> inventory;

  @override
  List<Object?> get props => [inventory];
}

class RepresentativeInventoryError extends RepresentativeInventoryState {
  const RepresentativeInventoryError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
