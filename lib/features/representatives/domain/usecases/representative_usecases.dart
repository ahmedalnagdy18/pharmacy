import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/representatives/domain/repositories/representatives_repository.dart';

class GetRepresentativesUseCase {
  const GetRepresentativesUseCase(this.repository);

  final RepresentativesRepository repository;

  Future<List<RepresentativeModel>> call() => repository.getRepresentatives();
}

class SaveRepresentativeUseCase {
  const SaveRepresentativeUseCase(this.repository);

  final RepresentativesRepository repository;

  Future<void> call(RepresentativeModel representative) {
    return repository.saveRepresentative(representative);
  }
}

class DeleteRepresentativeUseCase {
  const DeleteRepresentativeUseCase(this.repository);

  final RepresentativesRepository repository;

  Future<void> call(String id) => repository.deleteRepresentative(id);
}
