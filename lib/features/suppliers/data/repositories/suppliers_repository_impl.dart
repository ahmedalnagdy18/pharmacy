import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/data_source/suppliers_local_data_source.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_debt_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_model.dart';
import 'package:pharmacy/features/suppliers/data/model/supplier_payment_model.dart';
import 'package:pharmacy/features/suppliers/domain/repositories/suppliers_repository.dart';
import 'package:pharmacy/features/purchases/data/data_source/purchases_local_data_source.dart';

class SuppliersRepositoryImpl implements SuppliersRepository {
  const SuppliersRepositoryImpl({
    required this.source,
    required this.purchasesDataSource,
  });
  final SuppliersLocalDataSource source;
  final PurchasesLocalDataSource purchasesDataSource;
  @override
  Future<List<SupplierModel>> suppliers() => source.getSuppliers();
  @override
  Future<void> save(SupplierModel x) async {
    if (x.name.trim().isEmpty)
      throw const AppException('Supplier name is required.');
    await source.saveSupplier(x);
  }

  @override
  Future<void> delete(String id) async {
    final debts = await source.getDebts(id);
    final payments = await source.getPayments(id);
    final purchases = (await purchasesDataSource.getAll()).where(
      (item) => item.supplierId == id,
    );
    if (debts.isNotEmpty || payments.isNotEmpty || purchases.isNotEmpty) {
      throw const AppException(
        'Suppliers with purchases, debts, or payments cannot be deleted.',
      );
    }
    await source.deleteSupplier(id);
  }

  @override
  Future<List<SupplierDebtModel>> debts([String? id]) => source.getDebts(id);
  @override
  Future<List<SupplierPaymentModel>> payments([String? id]) =>
      source.getPayments(id);
  @override
  Future<void> createDebt(SupplierDebtModel debt) async {
    if (!debt.remainingAmount.isFinite || debt.remainingAmount <= 0) {
      throw const AppException('Debt amount must be greater than zero.');
    }
    await source.saveDebt(debt);
  }

  @override
  Future<void> payment(SupplierPaymentModel x) async {
    if (x.amount <= 0)
      throw const AppException('Payment amount must be greater than zero.');
    if (!x.amount.isFinite) {
      throw const AppException('Payment amount is invalid.');
    }
    final debt = (await source.getDebts())
        .where((d) => d.id == x.debtId)
        .firstOrNull;
    if (debt == null) throw const AppException('Debt was not found.');
    if (debt.supplierId != x.supplierId) {
      throw const AppException(
        'The selected debt does not belong to this supplier.',
      );
    }
    if (debt.status == DebtStatus.paid) {
      throw const AppException('This debt is already paid.');
    }
    if (x.amount > debt.remainingAmount)
      throw const AppException('Payment cannot exceed the remaining balance.');
    final remaining = debt.remainingAmount - x.amount;
    final normalizedRemaining = remaining.abs() < 0.000001 ? 0.0 : remaining;
    final invoicePurchases = (await purchasesDataSource.getAll())
        .where(
          (item) =>
              item.invoiceId == debt.purchaseId || item.id == debt.purchaseId,
        )
        .toList();
    await source.savePayment(x);
    await source.saveDebt(
      debt.copyWith(
        paidAmount: debt.paidAmount + x.amount,
        remainingAmount: normalizedRemaining,
        status: normalizedRemaining == 0 ? DebtStatus.paid : DebtStatus.pending,
      ),
    );
    var remainingPayment = x.amount;
    for (final purchase in invoicePurchases) {
      final applied = remainingPayment
          .clamp(0, purchase.total - purchase.paidAmount)
          .toDouble();
      remainingPayment -= applied;
      if (applied > 0) {
        await purchasesDataSource.save(
          purchase.copyWith(paidAmount: purchase.paidAmount + applied),
        );
      }
    }
  }
}
