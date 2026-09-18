import '../expense.dart';

abstract class ExpenseRepository {
  List<Expense> getExpenses();

  void addExpense(Expense expense);

  void updateExpense(Expense expense);

  void deleteExpense(String id);
}
