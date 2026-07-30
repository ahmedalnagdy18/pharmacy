import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/customers/data/data_source/customers_local_data_source.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';
import 'package:pharmacy/features/customers/domain/repositories/customers_repository.dart';
import 'package:pharmacy/features/sales/data/data_source/sales_local_data_source.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  const CustomersRepositoryImpl({
    required this.source,
    required this.salesDataSource,
  });
  final CustomersLocalDataSource source;
  final SalesLocalDataSource salesDataSource;
  @override
  Future<List<CustomerModel>> getCustomers() => source.getCustomers();
  @override
  Future<CustomerModel?> findByPhone(String phone) => source.findByPhone(phone);
  @override
  Future<void> saveCustomer(CustomerModel customer) async {
    if (customer.name.trim().isEmpty || customer.phone.trim().isEmpty)
      throw const AppException('Customer name and phone are required.');
    final existing = await source.findByPhone(customer.phone);
    if (existing != null && existing.id != customer.id)
      throw const AppException('A customer already uses this phone number.');
    await source.saveCustomer(customer);
  }

  @override
  Future<void> deleteCustomer(String id) async {
    final debts = await source.getDebts(id);
    if (debts.any((x) => x.status == DebtStatus.pending))
      throw const AppException(
        'Customers with outstanding debts cannot be deleted.',
      );
    await source.deleteCustomer(id);
  }

  @override
  Future<List<CustomerDebtModel>> getDebts([String? customerId]) =>
      source.getDebts(customerId);
  @override
  Future<List<CustomerPaymentModel>> getPayments([String? customerId]) =>
      source.getPayments(customerId);
  @override
  Future<void> createDebt(CustomerDebtModel debt) => source.saveDebt(debt);
  @override
  Future<void> recordPayment(CustomerPaymentModel payment) async {
    if (payment.amount <= 0)
      throw const AppException('Payment amount must be greater than zero.');
    if (!payment.amount.isFinite) {
      throw const AppException('Payment amount is invalid.');
    }
    final debt = (await source.getDebts())
        .where((x) => x.id == payment.debtId)
        .firstOrNull;
    if (debt == null) throw const AppException('Debt was not found.');
    if (debt.customerId != payment.customerId) {
      throw const AppException(
        'The selected debt does not belong to this customer.',
      );
    }
    if (debt.status == DebtStatus.paid)
      throw const AppException('This debt is already paid.');
    if (payment.amount > debt.remainingAmount)
      throw const AppException('Payment cannot exceed the remaining balance.');
    final remaining = debt.remainingAmount - payment.amount;
    final normalizedRemaining = remaining.abs() < 0.000001 ? 0.0 : remaining;
    final invoiceSales = (await salesDataSource.getAll())
        .where(
          (item) =>
              item.invoiceId == debt.invoiceId || item.id == debt.invoiceId,
        )
        .toList();
    await source.savePayment(payment);
    await source.saveDebt(
      debt.copyWith(
        paidAmount: debt.paidAmount + payment.amount,
        remainingAmount: normalizedRemaining,
        status: normalizedRemaining == 0 ? DebtStatus.paid : DebtStatus.pending,
        updatedAt: DateTime.now(),
      ),
    );
    var remainingPayment = payment.amount;
    for (final sale in invoiceSales) {
      final paidAmount = sale.amountPaid ?? sale.total;
      final applied = remainingPayment
          .clamp(0, sale.total - paidAmount)
          .toDouble();
      remainingPayment -= applied;
      if (applied > 0) {
        await salesDataSource.save(
          sale.copyWith(amountPaid: paidAmount + applied),
        );
      }
    }
  }
}
