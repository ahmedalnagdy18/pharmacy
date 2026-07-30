import 'package:hive/hive.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';

class SuppliersLocalDataSource {
  const SuppliersLocalDataSource(this.suppliers, this.debts, this.payments);
  final Box<SupplierModel> suppliers;
  final Box<SupplierDebtModel> debts;
  final Box<SupplierPaymentModel> payments;
  Future<List<SupplierModel>> getSuppliers() async =>
      suppliers.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  Future<void> saveSupplier(SupplierModel x) => suppliers.put(x.id, x);
  Future<void> deleteSupplier(String id) => suppliers.delete(id);
  Future<List<SupplierDebtModel>> getDebts([String? id]) async =>
      debts.values.where((x) => id == null || x.supplierId == id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
  Future<void> saveDebt(SupplierDebtModel x) => debts.put(x.id, x);
  Future<void> savePayment(SupplierPaymentModel x) => payments.put(x.id, x);
  Future<List<SupplierPaymentModel>> getPayments([String? id]) async =>
      payments.values.where((x) => id == null || x.supplierId == id).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
}
