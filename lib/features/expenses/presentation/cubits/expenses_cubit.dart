import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pharmacy/features/expenses/data/model/expense_model.dart';
import 'package:pharmacy/features/expenses/domain/usecases/expense_usecases.dart';
import 'package:uuid/uuid.dart';

sealed class ExpensesState { const ExpensesState(); }
class ExpensesInitial extends ExpensesState { const ExpensesInitial(); }
class ExpensesLoading extends ExpensesState { const ExpensesLoading(); }
class ExpensesLoaded extends ExpensesState { const ExpensesLoaded(this.items); final List<ExpenseModel> items; }
class ExpensesError extends ExpensesState { const ExpensesError(this.message); final String message; }

class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit(this.useCases) : super(const ExpensesInitial());
  final ExpenseUseCases useCases;
  Future<void> load() async { emit(const ExpensesLoading()); try { emit(ExpensesLoaded(await useCases.all())); } catch (e) { emit(ExpensesError(e.toString())); } }
  Future<void> add({required double amount, required String reason}) async { try { await useCases.save(ExpenseModel(id: const Uuid().v4(), amount: amount, reason: reason.trim(), date: DateTime.now())); await load(); } catch (e) { emit(ExpensesError(e.toString())); } }
  Future<void> update(ExpenseModel item, {required double amount, required String reason}) async { try { await useCases.save(ExpenseModel(id: item.id, amount: amount, reason: reason.trim(), date: item.date)); await load(); } catch (e) { emit(ExpensesError(e.toString())); } }
  Future<void> remove(String id) async { try { await useCases.delete(id); await load(); } catch (e) { emit(ExpensesError(e.toString())); } }
}
