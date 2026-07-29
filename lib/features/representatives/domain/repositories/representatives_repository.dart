import 'package:pharmacy/features/representatives/data/model/representative_model.dart';

abstract class RepresentativesRepository {
  Future<List<RepresentativeModel>> getRepresentatives();
  Future<RepresentativeModel?> getRepresentativeById(String id);
  Future<void> saveRepresentative(RepresentativeModel representative);
  Future<void> deleteRepresentative(String id);
}
