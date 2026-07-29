import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';

abstract class RepresentativeInventoryRepository {
  Future<List<RepresentativeInventoryModel>> getInventory();
  Future<List<RepresentativeInventoryModel>> getRepresentativeInventory(
    String representativeId,
  );
  Future<void> assignInventory({
    required String id,
    required String representativeId,
    required String productId,
    required int quantity,
  });
  Future<void> recordSoldQuantity({
    required String representativeId,
    required String productId,
    required int quantity,
  });
}
