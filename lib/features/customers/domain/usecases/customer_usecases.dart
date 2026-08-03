import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';
import 'package:pharmacy/features/customers/domain/repositories/customers_repository.dart';

class CustomerUseCases {
  const CustomerUseCases(this.repository);
  final CustomersRepository repository;
  Future<List<CustomerModel>> customers() => repository.getCustomers();
  Future<CustomerModel?> findByPhone(String phone) =>
      repository.findByPhone(phone);
  Future<void> save(CustomerModel x) => repository.saveCustomer(x);
  Future<void> delete(String id) => repository.deleteCustomer(id);
  Future<List<CustomerDebtModel>> debts([String? id]) =>
      repository.getDebts(id);
  Future<List<CustomerPaymentModel>> payments([String? id]) =>
      repository.getPayments(id);
  Future<void> payment(CustomerPaymentModel x) => repository.recordPayment(x);
  Future<void> addDebt(CustomerDebtModel x) => repository.createDebt(x);
}
