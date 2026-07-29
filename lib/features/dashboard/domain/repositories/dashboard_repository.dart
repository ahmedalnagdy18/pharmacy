import 'package:pharmacy/features/dashboard/data/model/dashboard_stats_model.dart';

abstract class DashboardRepository {
  Future<DashboardStatsModel> getStats();
}
