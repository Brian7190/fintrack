import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/budget/presentation/budget_page.dart';
import '../features/expenses/presentation/expenses_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/payments/presentation/payments_page.dart';
import '../features/statistics/presentation/statistics_page.dart';
import 'main_scaffold.dart';

class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String register = '/register';

  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String budget = '/budget';
  static const String statistics = '/statistics';
  static const String payments = '/payments';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginPage(),
    ),

    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterPage(),
    ),

    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomePage(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.expenses,
              builder: (context, state) => const ExpensesPage(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.budget,
              builder: (context, state) => const BudgetPage(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.statistics,
              builder: (context, state) => const StatisticsPage(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.payments,
              builder: (context, state) => const PaymentsPage(),
            ),
          ],
        ),
      ],
    ),
  ],
);
