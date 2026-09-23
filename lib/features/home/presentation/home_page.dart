import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';

import '../../auth/presentation/auth_provider.dart';

import '../../budget/domain/monthly_budget.dart';
import '../../budget/presentation/budget_provider.dart';

import '../../expenses/domain/expense.dart';
import '../../expenses/domain/expense_category.dart';
import '../../expenses/presentation/expense_category_ui.dart';
import '../../expenses/presentation/expenses_provider.dart';

import '../../payments/domain/payment.dart';
import '../../payments/presentation/payments_provider.dart';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

// ====================================================
// CERRAR SESIÓN
// ====================================================

Future<void> _signOut(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authRepositoryProvider).signOut();

    ref.invalidate(expensesProvider);

    ref.invalidate(expenseFilterProvider);

    ref.invalidate(paymentsProvider);

    ref.invalidate(budgetStateProvider);

    ref.invalidate(budgetProvider);

    if (!context.mounted) {
      return;
    }

    context.go(AppRoutes.login);
  } catch (_) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No fue posible cerrar la sesión.')),
    );
  }
}

// ====================================================
// HOME
// ====================================================

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(currentUserProfileProvider);

    final userName = profileState.asData?.value?.name;

    final budget = ref.watch(budgetProvider);

    final spent = ref.watch(currentMonthExpensesTotalProvider);

    final expenses = ref.watch(currentMonthExpensesProvider);

    final payments = ref.watch(paymentsProvider);

    final nearestPayment = _getNearestPayment(payments);

    final available = budget == null ? null : budget - spent;

    final percentageUsed = budget == null || budget <= 0
        ? 0.0
        : (spent / budget) * 100;

    final progress = budget == null || budget <= 0
        ? 0.0
        : (spent / budget).clamp(0.0, 1.0).toDouble();

    final isOverBudget = budget != null && spent > budget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              await _signOut(context, ref);
            },
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // BIENVENIDA
              // ==================================================
              _WelcomeHeader(name: userName),

              const SizedBox(height: 20),

              // ==================================================
              // PRESUPUESTO
              // ==================================================
              if (budget == null)
                _NoBudgetHero(spent: spent)
              else
                _BudgetHero(
                  budget: budget,
                  spent: spent,
                  available: available!,
                  percentageUsed: percentageUsed,
                  progress: progress,
                  isOverBudget: isOverBudget,
                ),

              // ==================================================
              // AVISO DE PRESUPUESTO EXCEDIDO
              // ==================================================
              if (isOverBudget) ...[
                const SizedBox(height: 14),
                _BudgetExceededNotice(amount: spent - budget),
              ],

              const SizedBox(height: 28),

              // ==================================================
              // RESUMEN
              // ==================================================
              const _SectionTitle(title: 'Resumen mensual'),

              const SizedBox(height: 13),

              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.payments_outlined,
                      title: 'Gastado',
                      value: _moneyFormat.format(spent),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: isOverBudget ? 'Saldo' : 'Presupuesto',
                      value: budget == null
                          ? 'Sin definir'
                          : isOverBudget
                          ? _moneyFormat.format(available)
                          : _moneyFormat.format(budget),
                      valueColor: isOverBudget ? AppColors.error : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==================================================
              // PRÓXIMO PAGO
              // ==================================================
              _SectionTitle(
                title: 'Próximo pago',
                actionText: 'Ver todos',
                onAction: () {
                  context.go(AppRoutes.payments);
                },
              ),

              const SizedBox(height: 12),

              if (nearestPayment == null)
                const _NoUpcomingPayment()
              else
                _UpcomingPaymentCard(payment: nearestPayment),

              const SizedBox(height: 28),

              // ==================================================
              // GASTOS RECIENTES
              // ==================================================
              _SectionTitle(
                title: 'Gastos recientes',
                actionText: 'Ver todos',
                onAction: () {
                  context.go(AppRoutes.expenses);
                },
              ),

              const SizedBox(height: 12),

              if (expenses.isEmpty)
                const _NoRecentExpenses()
              else
                for (final expense in expenses.take(3))
                  _RecentExpense(expense: expense),
            ],
          ),
        ),
      ),
    );
  }

  Payment? _getNearestPayment(List<Payment> payments) {
    if (payments.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final futurePayments = payments.where((payment) {
      final paymentDate = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );

      return !paymentDate.isBefore(today);
    }).toList();

    if (futurePayments.isEmpty) {
      return null;
    }

    futurePayments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return futurePayments.first;
  }
}

// ====================================================
// BIENVENIDA
// ====================================================

class _WelcomeHeader extends StatelessWidget {
  final String? name;

  const _WelcomeHeader({this.name});

  @override
  Widget build(BuildContext context) {
    final displayName = name == null || name!.trim().isEmpty
        ? 'Bienvenido'
        : 'Hola, ${name!.trim().split(' ').first}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_outline,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  MonthlyBudget.currentPeriodLabel(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.calendar_month_outlined,
            color: AppColors.textSecondary,
            size: 21,
          ),
        ],
      ),
    );
  }
}

// ====================================================
// TARJETA PRINCIPAL DEL PRESUPUESTO
// ====================================================

class _BudgetHero extends StatelessWidget {
  final double budget;
  final double spent;
  final double available;
  final double percentageUsed;
  final double progress;
  final bool isOverBudget;

  const _BudgetHero({
    required this.budget,
    required this.spent,
    required this.available,
    required this.percentageUsed,
    required this.progress,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  isOverBudget ? 'Saldo excedido' : 'Disponible este mes',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),

          // ==================================================
          // BADGE DE EXCESO
          // ==================================================
          if (isOverBudget) ...[
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 17,
                    color: AppColors.error,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'PRESUPUESTO EXCEDIDO',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // ==================================================
          // SALDO
          // ==================================================
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _moneyFormat.format(available),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                height: 1,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 10),

          if (isOverBudget)
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                Text(
                  'Presupuesto: ${_moneyFormat.format(budget)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const Text('•', style: TextStyle(color: Colors.white54)),
                Text(
                  'Gastado: ${_moneyFormat.format(spent)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            )
          else
            Text(
              'Presupuesto: ${_moneyFormat.format(budget)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),

          const SizedBox(height: 24),

          // ==================================================
          // PROGRESO
          // ==================================================
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 9),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentageUsed.toStringAsFixed(1)}% utilizado',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              Text(
                isOverBudget
                    ? 'Exceso: ${_moneyFormat.format(spent - budget)}'
                    : 'Gastado: ${_moneyFormat.format(spent)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================
// SIN PRESUPUESTO
// ====================================================

class _NoBudgetHero extends StatelessWidget {
  final double spent;

  const _NoBudgetHero({required this.spent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Organiza tu presupuesto',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Define cuánto deseas administrar durante este mes.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),

          if (spent > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Ya has gastado ${_moneyFormat.format(spent)}.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],

          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primaryDark,
              ),
              onPressed: () {
                context.go(AppRoutes.budget);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ingresar presupuesto'),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// ALERTA DE EXCESO
// ====================================================

class _BudgetExceededNotice extends StatelessWidget {
  final double amount;

  const _BudgetExceededNotice({required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: AppColors.error),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Presupuesto excedido',
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  'Has superado el límite mensual por '
                  '${_moneyFormat.format(amount)}.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// TÍTULOS
// ====================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onAction;

  const _SectionTitle({required this.title, this.actionText, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        if (actionText != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionText!)),
      ],
    );
  }
}

// ====================================================
// MÉTRICAS
// ====================================================

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primaryDark, size: 20),
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 4),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// PRÓXIMO PAGO
// ====================================================

class _UpcomingPaymentCard extends StatelessWidget {
  final Payment payment;

  const _UpcomingPaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(payment.dueDate);

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final dueDate = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );

    final days = dueDate.difference(today).inDays;

    String status;

    if (days == 0) {
      status = 'Vence hoy';
    } else if (days == 1) {
      status = 'Vence mañana';
    } else {
      status = 'En $days días';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primaryDark,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$formattedDate • $status',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            _moneyFormat.format(payment.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUpcomingPayment extends StatelessWidget {
  const _NoUpcomingPayment();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available_outlined, color: AppColors.primaryDark),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No tienes pagos próximos registrados.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// GASTOS
// ====================================================

class _RecentExpense extends StatelessWidget {
  final Expense expense;

  const _RecentExpense({required this.expense});

  @override
  Widget build(BuildContext context) {
    final categoryColor = expenseCategoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              expenseCategoryIcon(expense.category),
              color: categoryColor,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  expense.category.label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          Text(
            _moneyFormat.format(expense.amount),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoRecentExpenses extends StatelessWidget {
  const _NoRecentExpenses();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 34,
            color: AppColors.primaryDark,
          ),
          SizedBox(height: 10),
          Text(
            'No hay gastos registrados',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tus últimos gastos aparecerán aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
