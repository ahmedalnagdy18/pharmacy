import 'package:pharmacy/features/customers/data/model/customer_debt_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_model.dart';
import 'package:pharmacy/features/customers/data/model/customer_payment_model.dart';

abstract class CustomersRepository {
  Future<List<CustomerModel>> getCustomers();
  Future<CustomerModel?> findByPhone(String phone);
  Future<void> saveCustomer(CustomerModel customer);
  Future<void> deleteCustomer(String id);
  Future<List<CustomerDebtModel>> getDebts([String? customerId]);
  Future<List<CustomerPaymentModel>> getPayments([String? customerId]);
  Future<void> createDebt(CustomerDebtModel debt);
  Future<void> recordPayment(CustomerPaymentModel payment);
}
