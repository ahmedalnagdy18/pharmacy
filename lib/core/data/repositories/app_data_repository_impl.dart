import 'package:pharmacy/core/database/hive_service.dart';
import 'package:pharmacy/core/domain/repositories/app_data_repository.dart';

class AppDataRepositoryImpl implements AppDataRepository {
  const AppDataRepositoryImpl();

  @override
  Future<void> clearAllData() => HiveService.clearAllData();
}
