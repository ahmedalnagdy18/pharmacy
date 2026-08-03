import 'package:hive/hive.dart';
import 'package:pharmacy/features/expenses/data/model/expense_model.dart';

class ExpensesLocalDataSource {
  const ExpensesLocalDataSource(this.box);
  final Box<ExpenseModel> box;
  Future<List<ExpenseModel>> getAll() async => box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  Future<void> save(ExpenseModel value) => box.put(value.id, value);
  Future<void> delete(String id) => box.delete(id);
}
