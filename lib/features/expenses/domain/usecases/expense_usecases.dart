import 'package:pharmacy/core/errors/app_exception.dart';
import 'package:pharmacy/features/expenses/data/data_source/expenses_local_data_source.dart';
import 'package:pharmacy/features/expenses/data/model/expense_model.dart';

class ExpenseUseCases {
  const ExpenseUseCases(this.source);
  final ExpensesLocalDataSource source;
  Future<List<ExpenseModel>> all() => source.getAll();
  Future<void> save(ExpenseModel expense) {
    if (!expense.amount.isFinite || expense.amount <= 0 || expense.reason.trim().isEmpty) {
      throw const AppException('Enter a valid amount and reason.');
    }
    return source.save(expense);
  }
  Future<void> delete(String id) => source.delete(id);
}
