import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';
import 'package:pharmacy/features/suppliers/domain/repositories/suppliers_repository.dart';

class SupplierUseCases {
  const SupplierUseCases(this.repository);
  final SuppliersRepository repository;
  Future<List<SupplierModel>> suppliers() => repository.suppliers();
  Future<void> save(SupplierModel x) => repository.save(x);
  Future<void> delete(String id) => repository.delete(id);
  Future<List<SupplierDebtModel>> debts([String? id]) => repository.debts(id);
  Future<List<SupplierPaymentModel>> payments([String? id]) =>
      repository.payments(id);
  Future<void> payment(SupplierPaymentModel x) => repository.payment(x);
  Future<void> addDebt(SupplierDebtModel x) => repository.createDebt(x);
}
