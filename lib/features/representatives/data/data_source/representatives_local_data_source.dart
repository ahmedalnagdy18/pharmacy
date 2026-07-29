import 'package:hive/hive.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';

class RepresentativesLocalDataSource {
  const RepresentativesLocalDataSource(this.box);

  final Box<RepresentativeModel> box;

  Future<List<RepresentativeModel>> getAll() async {
    final representatives = box.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return representatives;
  }

  Future<RepresentativeModel?> getById(String id) async => box.get(id);

  Future<void> save(RepresentativeModel representative) async {
    await box.put(representative.id, representative);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }
}
