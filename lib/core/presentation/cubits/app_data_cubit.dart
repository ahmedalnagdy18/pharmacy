import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/core/domain/usecases/clear_app_data_usecase.dart';
import 'package:pharmacy/core/presentation/cubits/app_data_state.dart';

class AppDataCubit extends Cubit<AppDataState> {
  AppDataCubit(this.clearAppData) : super(const AppDataInitial());

  final ClearAppDataUseCase clearAppData;

  Future<void> clearAllData() async {
    emit(const AppDataLoading());
    try {
      await clearAppData();
      emit(const AppDataCleared());
    } catch (error) {
      emit(AppDataError(error.toString()));
    }
  }
}
