import 'package:hive/hive.dart';
import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';

class CustomersLocalDataSource {
  const CustomersLocalDataSource(this.customers, this.debts, this.payments);
  final Box<CustomerModel> customers;
  final Box<CustomerDebtModel> debts;
  final Box<CustomerPaymentModel> payments;
  Future<List<CustomerModel>> getCustomers() async =>
      customers.values.toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  Future<CustomerModel?> getCustomer(String id) async => customers.get(id);
  Future<CustomerModel?> findByPhone(String phone) async {
    final value = phone.trim();
    if (value.isEmpty) return null;
    for (final customer in customers.values) {
      if (customer.phone == value) return customer;
    }
    return null;
  }

  Future<void> saveCustomer(CustomerModel customer) =>
      customers.put(customer.id, customer);
  Future<void> deleteCustomer(String id) => customers.delete(id);
  Future<List<CustomerDebtModel>> getDebts([String? customerId]) async {
    final values =
        debts.values
            .where((x) => customerId == null || x.customerId == customerId)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return values;
  }

  Future<void> saveDebt(CustomerDebtModel debt) => debts.put(debt.id, debt);
  Future<void> deleteDebt(String id) => debts.delete(id);
  Future<void> savePayment(CustomerPaymentModel payment) =>
      payments.put(payment.id, payment);
  Future<List<CustomerPaymentModel>> getPayments([String? customerId]) async {
    final values =
        payments.values
            .where((x) => customerId == null || x.customerId == customerId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return values;
  }
}
