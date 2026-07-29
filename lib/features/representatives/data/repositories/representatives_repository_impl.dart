import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/representatives/data/data_source/representatives_local_data_source.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/domain/repositories/representatives_repository.dart';

class RepresentativesRepositoryImpl implements RepresentativesRepository {
  const RepresentativesRepositoryImpl(this.localDataSource);

  final RepresentativesLocalDataSource localDataSource;

  @override
  Future<List<RepresentativeModel>> getRepresentatives() {
    return localDataSource.getAll();
  }

  @override
  Future<RepresentativeModel?> getRepresentativeById(String id) {
    return localDataSource.getById(id);
  }

  @override
  Future<void> saveRepresentative(RepresentativeModel representative) {
    if (representative.name.trim().isEmpty) {
      throw const AppException('Representative name is required.');
    }
    if (representative.phone.trim().isEmpty) {
      throw const AppException('Phone is required.');
    }
    return localDataSource.save(representative);
  }

  @override
  Future<void> deleteRepresentative(String id) => localDataSource.delete(id);
}
