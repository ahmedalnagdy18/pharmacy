import 'package:pharmacy/features/dashboard/data/model/dashboard_stats_model.dart';
import 'package:pharmacy/features/dashboard/domain/repositories/dashboard_repository.dart';

class GetDashboardStatsUseCase {
  const GetDashboardStatsUseCase(this.repository);

  final DashboardRepository repository;

  Future<DashboardStatsModel> call() => repository.getStats();
}
