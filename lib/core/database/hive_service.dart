import 'package:hive_flutter/hive_flutter.dart';
import 'package:pharmacy/core/constants/hive_boxes.dart';
import 'package:pharmacy/features/products/data/model/medicine_model.dart';
import 'package:pharmacy/features/representative_inventory/data/model/representative_inventory_model.dart';
import 'package:pharmacy/features/representatives/data/model/representative_model.dart';
import 'package:pharmacy/features/sales/data/model/sale_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/purchases/data/model/purchase_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';

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
    if (!Hive.isAdapterRegistered(4))
      Hive.registerAdapter(CustomerModelAdapter());
    if (!Hive.isAdapterRegistered(5))
      Hive.registerAdapter(CustomerDebtModelAdapter());
    if (!Hive.isAdapterRegistered(6))
      Hive.registerAdapter(CustomerPaymentModelAdapter());
    if (!Hive.isAdapterRegistered(7))
      Hive.registerAdapter(SupplierModelAdapter());
    if (!Hive.isAdapterRegistered(8))
      Hive.registerAdapter(PurchaseModelAdapter());
    if (!Hive.isAdapterRegistered(9))
      Hive.registerAdapter(SupplierDebtModelAdapter());
    if (!Hive.isAdapterRegistered(10))
      Hive.registerAdapter(SupplierPaymentModelAdapter());

    await Future.wait([
      Hive.openBox<MedicineModel>(HiveBoxes.products),
      Hive.openBox<RepresentativeModel>(HiveBoxes.representatives),
      Hive.openBox<RepresentativeInventoryModel>(
        HiveBoxes.representativeInventory,
      ),
      Hive.openBox<SaleModel>(HiveBoxes.sales),
      Hive.openBox<CustomerModel>(HiveBoxes.customers),
      Hive.openBox<CustomerDebtModel>(HiveBoxes.customerDebts),
      Hive.openBox<CustomerPaymentModel>(HiveBoxes.customerPayments),
      Hive.openBox<SupplierModel>(HiveBoxes.suppliers),
      Hive.openBox<PurchaseModel>(HiveBoxes.purchases),
      Hive.openBox<SupplierDebtModel>(HiveBoxes.supplierDebts),
      Hive.openBox<SupplierPaymentModel>(HiveBoxes.supplierPayments),
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
      Hive.box<CustomerModel>(HiveBoxes.customers).clear(),
      Hive.box<CustomerDebtModel>(HiveBoxes.customerDebts).clear(),
      Hive.box<CustomerPaymentModel>(HiveBoxes.customerPayments).clear(),
      Hive.box<SupplierModel>(HiveBoxes.suppliers).clear(),
      Hive.box<PurchaseModel>(HiveBoxes.purchases).clear(),
      Hive.box<SupplierDebtModel>(HiveBoxes.supplierDebts).clear(),
      Hive.box<SupplierPaymentModel>(HiveBoxes.supplierPayments).clear(),
    ]);
  }
}
