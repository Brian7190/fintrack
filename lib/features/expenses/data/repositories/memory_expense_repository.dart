import '../../domain/expense.dart';
import '../../domain/repositories/expense_repository.dart';

class MemoryExpenseRepository implements ExpenseRepository {
  final List<Expense> _expenses = [];

  @override
  List<Expense> getExpenses() {
    return List.unmodifiable(_expenses);
  }

  @override
  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
  }

  @override
  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((item) => item.id == expense.id);

    if (index == -1) {
      return;
    }

    _expenses[index] = expense;
  }

  @override
  void deleteExpense(String id) {
    _expenses.removeWhere((expense) => expense.id == id);
  }
}
