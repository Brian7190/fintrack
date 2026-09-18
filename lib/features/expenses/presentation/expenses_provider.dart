import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expense.dart';

class ExpensesNotifier extends Notifier<List<Expense>> {
  @override
  List<Expense> build() {
    return [];
  }

  void addExpense({required String name, required double amount}) {
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      date: DateTime.now(),
    );

    state = [expense, ...state];
  }

  void updateExpense({
    required String id,
    required String name,
    required double amount,
  }) {
    state = [
      for (final expense in state)
        if (expense.id == id)
          expense.copyWith(name: name, amount: amount)
        else
          expense,
    ];
  }

  void deleteExpense(String id) {
    state = state.where((expense) => expense.id != id).toList();
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider);

  return expenses.fold<double>(0, (total, expense) => total + expense.amount);
});
