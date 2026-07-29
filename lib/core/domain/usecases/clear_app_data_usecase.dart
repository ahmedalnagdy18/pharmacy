import 'package:pharmacy/core/domain/repositories/app_data_repository.dart';

class ClearAppDataUseCase {
  const ClearAppDataUseCase(this.repository);

  final AppDataRepository repository;

  Future<void> call() => repository.clearAllData();
}
