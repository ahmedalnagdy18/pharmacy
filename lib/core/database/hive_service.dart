import 'package:hive_flutter/hive_flutter.dart';
import 'package:pharmacy/core/constants/hive_boxes.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';

class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicineModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RepresentativeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(RepresentativeInventoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SaleModelAdapter());
    }

    await Future.wait([
      Hive.openBox<MedicineModel>(HiveBoxes.products),
      Hive.openBox<RepresentativeModel>(HiveBoxes.representatives),
      Hive.openBox<RepresentativeInventoryModel>(
        HiveBoxes.representativeInventory,
      ),
      Hive.openBox<SaleModel>(HiveBoxes.sales),
    ]);
  }

  static Future<void> clearAllData() async {
    await Future.wait([
      Hive.box<MedicineModel>(HiveBoxes.products).clear(),
      Hive.box<RepresentativeModel>(HiveBoxes.representatives).clear(),
      Hive.box<RepresentativeInventoryModel>(
        HiveBoxes.representativeInventory,
      ).clear(),
      Hive.box<SaleModel>(HiveBoxes.sales).clear(),
    ]);
  }
}
