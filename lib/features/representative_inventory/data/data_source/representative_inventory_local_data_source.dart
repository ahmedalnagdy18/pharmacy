import 'package:hive/hive.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';

class RepresentativeInventoryLocalDataSource {
  const RepresentativeInventoryLocalDataSource(this.box);

  final Box<RepresentativeInventoryModel> box;

  Future<List<RepresentativeInventoryModel>> getAll() async {
    final inventory = box.values.toList()
      ..sort((a, b) => a.representativeId.compareTo(b.representativeId));
    return inventory;
  }

  Future<RepresentativeInventoryModel?> getById(String id) async => box.get(id);

  Future<RepresentativeInventoryModel?> getByRepresentativeAndProduct({
    required String representativeId,
    required String productId,
  }) async {
    for (final item in box.values) {
      if (item.representativeId == representativeId &&
          item.productId == productId) {
        return item;
      }
    }
    return null;
  }

  Future<List<RepresentativeInventoryModel>> getByRepresentative(
    String representativeId,
  ) async {
    return box.values
        .where((item) => item.representativeId == representativeId)
        .toList();
  }

  Future<void> save(RepresentativeInventoryModel inventory) async {
    await box.put(inventory.id, inventory);
  }

  Future<void> delete(String id) async {
    await box.delete(id);
  }
}
