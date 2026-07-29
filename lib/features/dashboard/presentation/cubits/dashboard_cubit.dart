import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/dashboard/domain/usecases/dashboard_usecases.dart';
import 'package:pharmacy/features/dashboard/presentation/cubits/dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this.getDashboardStats) : super(const DashboardInitial());

  final GetDashboardStatsUseCase getDashboardStats;

  Future<void> load() async {
    emit(const DashboardLoading());
    try {
      emit(DashboardLoaded(await getDashboardStats()));
    } catch (error) {
      emit(DashboardError(error.toString()));
    }
  }
}
