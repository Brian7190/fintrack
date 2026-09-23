import '../admin_user_budget.dart';
import '../admin_user_summary.dart';

abstract class AdminRepository {
  Stream<List<AdminUserSummary>> watchUsers();

  Stream<AdminUserBudget?> watchCurrentBudget(String userId);

  Stream<double> watchCurrentMonthSpent(String userId);
}
