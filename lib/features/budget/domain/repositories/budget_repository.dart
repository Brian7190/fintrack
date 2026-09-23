import '../monthly_budget.dart';

abstract class BudgetRepository {
  Stream<List<MonthlyBudget>> watchBudgets();

  Future<void> saveBudget(MonthlyBudget budget);

  Future<void> deleteBudget(String periodKey);
}
