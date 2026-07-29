import 'package:equatable/equatable.dart';

abstract class AppDataState extends Equatable {
  const AppDataState();

  @override
  List<Object?> get props => [];
}

class AppDataInitial extends AppDataState {
  const AppDataInitial();
}

class AppDataLoading extends AppDataState {
  const AppDataLoading();
}

class AppDataCleared extends AppDataState {
  const AppDataCleared();
}

class AppDataError extends AppDataState {
  const AppDataError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
