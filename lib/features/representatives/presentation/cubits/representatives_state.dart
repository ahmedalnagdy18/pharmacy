import 'package:equatable/equatable.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';

abstract class RepresentativesState extends Equatable {
  const RepresentativesState();

  @override
  List<Object?> get props => [];
}

class RepresentativesInitial extends RepresentativesState {
  const RepresentativesInitial();
}

class RepresentativesLoading extends RepresentativesState {
  const RepresentativesLoading();
}

class RepresentativesLoaded extends RepresentativesState {
  const RepresentativesLoaded(this.representatives);

  final List<RepresentativeModel> representatives;

  @override
  List<Object?> get props => [representatives];
}

class RepresentativesError extends RepresentativesState {
  const RepresentativesError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
