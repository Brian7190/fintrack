import 'package:go_router/go_router.dart';

import '../features/admin/presentation/admin_dashboard_page.dart';
import '../features/auth/presentation/login_page.dart';
import '../features/auth/presentation/register_page.dart';
import '../features/budget/presentation/budget_page.dart';
import '../features/expenses/presentation/expenses_page.dart';
import '../features/home/presentation/home_page.dart';
import '../features/payments/presentation/payments_page.dart';
import '../features/statistics/presentation/statistics_page.dart';
import 'main_scaffold.dart';
import '../features/admin/presentation/admin_user_detail_page.dart';

class AppRoutes {
  AppRoutes._();

  // ==================================================
  // AUTENTICACIÓN
  // ==================================================

  static const String login = '/login';
  static const String register = '/register';

  // ==================================================
  // USUARIO
  // ==================================================

  static const String home = '/home';
  static const String expenses = '/expenses';
  static const String budget = '/budget';
  static const String statistics = '/statistics';
  static const String payments = '/payments';

  // ==================================================
  // ADMINISTRACIÓN
  // ==================================================

  static const String admin = '/admin';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  routes: [
    // ==================================================
    // LOGIN
    // ==================================================
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) {
        return const LoginPage();
      },
    ),

    // ==================================================
    // REGISTRO
    // ==================================================
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) {
        return const RegisterPage();
      },
    ),

    // ==================================================
    // NAVEGACIÓN PRINCIPAL
    // ==================================================
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainScaffold(navigationShell: navigationShell);
      },
      branches: [
        // ==================================================
        // 0 - INICIO
        // ==================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) {
                return const HomePage();
              },
            ),
          ],
        ),

        // ==================================================
        // 1 - GASTOS
        // ==================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.expenses,
              builder: (context, state) {
                return const ExpensesPage();
              },
            ),
          ],
        ),

        // ==================================================
        // 2 - PRESUPUESTO
        // ==================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.budget,
              builder: (context, state) {
                return const BudgetPage();
              },
            ),
          ],
        ),

        // ==================================================
        // 3 - ESTADÍSTICAS
        // ==================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.statistics,
              builder: (context, state) {
                return const StatisticsPage();
              },
            ),
          ],
        ),

        // ==================================================
        // 4 - PAGOS
        // ==================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.payments,
              builder: (context, state) {
                return const PaymentsPage();
              },
            ),
          ],
        ),

        // ==================================================
        // 5 - ADMINISTRACIÓN
        // ==================================================
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.admin,
              builder: (context, state) {
                return const AdminDashboardPage();
              },
              routes: [
                GoRoute(
                  path: 'user/:uid',
                  builder: (context, state) {
                    final userId = state.pathParameters['uid'];

                    if (userId == null || userId.isEmpty) {
                      return const AdminDashboardPage();
                    }

                    return AdminUserDetailPage(userId: userId);
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
