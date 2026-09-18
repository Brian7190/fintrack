import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/memory_expense_repository.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';
import '../domain/repositories/expense_repository.dart';

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return MemoryExpenseRepository();
});

class ExpensesNotifier extends Notifier<List<Expense>> {
  ExpenseRepository get _repository {
    return ref.read(expenseRepositoryProvider);
  }

  @override
  List<Expense> build() {
    return _repository.getExpenses();
  }

  void addExpense({
    required String name,
    required double amount,
    required ExpenseCategory category,
  }) {
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      date: DateTime.now(),
      category: category,
    );

    _repository.addExpense(expense);

    state = _repository.getExpenses();
  }

  void updateExpense({
    required String id,
    required String name,
    required double amount,
    required ExpenseCategory category,
  }) {
    final currentExpense = state.firstWhere((expense) => expense.id == id);

    final updatedExpense = currentExpense.copyWith(
      name: name,
      amount: amount,
      category: category,
    );

    _repository.updateExpense(updatedExpense);

    state = _repository.getExpenses();
  }

  void deleteExpense(String id) {
    _repository.deleteExpense(id);

    state = _repository.getExpenses();
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider);

  return expenses.fold<double>(0, (total, expense) => total + expense.amount);
});

final expensesByCategoryProvider = Provider<Map<ExpenseCategory, double>>((
  ref,
) {
  final expenses = ref.watch(expensesProvider);

  final totals = <ExpenseCategory, double>{};

  for (final expense in expenses) {
    totals.update(
      expense.category,
      (current) => current + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }

  return totals;
});
