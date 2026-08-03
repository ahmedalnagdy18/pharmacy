import 'package:hive/hive.dart';
import 'package:pharmacy/features/representatives/data/model/representative_collection_model.dart';

class RepresentativeCollectionsLocalDataSource {
  const RepresentativeCollectionsLocalDataSource(this.box);
  final Box<RepresentativeCollectionModel> box;
  Future<List<RepresentativeCollectionModel>> getAll() async => box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  Future<void> save(RepresentativeCollectionModel value) => box.put(value.id, value);
  Future<bool> hasInvoiceCollections(String invoiceId) async => box.values.any((x) => x.invoiceId == invoiceId);
}
