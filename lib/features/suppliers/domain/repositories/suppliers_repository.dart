import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';

abstract class SuppliersRepository {
  Future<List<SupplierModel>> suppliers();
  Future<void> save(SupplierModel x);
  Future<void> delete(String id);
  Future<List<SupplierDebtModel>> debts([String? id]);
  Future<List<SupplierPaymentModel>> payments([String? id]);
  Future<void> createDebt(SupplierDebtModel debt);
  Future<void> payment(SupplierPaymentModel x);
}
