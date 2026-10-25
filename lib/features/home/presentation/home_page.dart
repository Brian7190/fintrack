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
import '../../payments/presentation/payment_reminder_utils.dart';
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

    final isAdmin = ref.watch(isAdminProvider);

    final budget = ref.watch(budgetProvider);

    final spent = ref.watch(currentMonthExpensesTotalProvider);

    final expenses = ref.watch(currentMonthExpensesProvider);

    final payments = ref.watch(paymentsProvider);

    final paymentReminder = PaymentReminderSummary.fromPayments(payments);

    final nearestPayment =
        paymentReminder.priorityPayment ?? _getNearestPayment(payments);

    final available = budget == null ? null : budget - spent;

    final percentageUsed = budget == null || budget <= 0
        ? 0.0
        : (spent / budget) * 100;

    final progress = budget == null || budget <= 0
        ? 0.0
        : (spent / budget).clamp(0.0, 1.0).toDouble();

    final isOverBudget = budget != null && spent > budget;

    // Avisamos antes de llegar al límite para que el usuario pueda reaccionar
    // a tiempo. Al excederlo se conserva la alerta roja existente.
    final isBudgetWarning =
        budget != null && budget > 0 && percentageUsed >= 80 && !isOverBudget;

    return Scaffold(
      appBar: AppBar(
        title: const Text('FinTrack'),
        actions: [
          // ==================================================
          // ADMIN
          // ==================================================
          if (isAdmin)
            IconButton(
              tooltip: 'Administración',
              onPressed: () {
                context.go(AppRoutes.admin);
              },
              icon: const Icon(Icons.admin_panel_settings_outlined),
            ),

          // ==================================================
          // CERRAR SESIÓN
          // ==================================================
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
              // ALERTA DE PRESUPUESTO
              // ==================================================
              if (isBudgetWarning) ...[
                const SizedBox(height: 14),
                _BudgetWarningNotice(
                  percentageUsed: percentageUsed,
                  available: available!,
                ),
              ] else if (isOverBudget) ...[
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

              if (paymentReminder.hasAlert) ...[
                _HomePaymentReminderNotice(summary: paymentReminder),
                const SizedBox(height: 10),
              ],

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
// TARJETA PRINCIPAL
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
// ALERTA PRESUPUESTO
// ====================================================

class _BudgetWarningNotice extends StatelessWidget {
  final double percentageUsed;
  final double available;

  const _BudgetWarningNotice({
    required this.percentageUsed,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE6A700).withValues(alpha: 0.28),
        ),
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
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Color(0xFFB77900),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tu presupuesto está por agotarse',
                  style: TextStyle(
                    color: Color(0xFF8A5A00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Has utilizado ${percentageUsed.toStringAsFixed(1)}% de tu '
                  'presupuesto. Te quedan ${_moneyFormat.format(available)}.',
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

class _HomePaymentReminderNotice extends StatelessWidget {
  final PaymentReminderSummary summary;

  const _HomePaymentReminderNotice({required this.summary});

  @override
  Widget build(BuildContext context) {
    final overdue = summary.overdueCount > 0;
    final payment = summary.priorityPayment;

    String text;
    if (overdue) {
      text = summary.overdueCount == 1
          ? 'Tienes un pago vencido pendiente.'
          : 'Tienes ${summary.overdueCount} pagos vencidos pendientes.';
    } else if (summary.dueTodayCount > 0) {
      text = summary.dueTodayCount == 1
          ? 'Tienes un pago que vence hoy.'
          : 'Tienes ${summary.dueTodayCount} pagos que vencen hoy.';
    } else if (summary.dueTomorrowCount > 0) {
      text = summary.dueTomorrowCount == 1
          ? 'Tienes un pago que vence mañana.'
          : 'Tienes ${summary.dueTomorrowCount} pagos que vencen mañana.';
    } else {
      text = payment == null
          ? 'Tienes un pago próximo.'
          : '${payment.name} vence ${paymentDueLabel(payment.dueDate).toLowerCase()}.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: overdue ? const Color(0xFFFFEEEE) : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: overdue ? const Color(0xFFF2B8B5) : const Color(0xFFF0D9A6),
        ),
      ),
      child: Row(
        children: [
          Icon(
            overdue
                ? Icons.warning_amber_rounded
                : Icons.notifications_active_outlined,
            color: overdue ? AppColors.error : const Color(0xFF9A6700),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: overdue ? AppColors.error : const Color(0xFF7A5200),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingPaymentCard extends StatelessWidget {
  final Payment payment;

  const _UpcomingPaymentCard({required this.payment});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(payment.dueDate);

    final days = paymentDaysUntil(payment.dueDate);
    final status = paymentDueLabel(payment.dueDate);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: days <= 0
            ? const Color(0xFFFFF4F4)
            : days <= 3
            ? const Color(0xFFFFFAEE)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: days <= 0
              ? const Color(0xFFF2B8B5)
              : days <= 3
              ? const Color(0xFFF0D9A6)
              : AppColors.border,
        ),
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
                  style: TextStyle(
                    fontSize: 12,
                    color: days <= 0
                        ? AppColors.error
                        : days <= 3
                        ? const Color(0xFF9A6700)
                        : AppColors.textSecondary,
                    fontWeight: days <= 3 ? FontWeight.w600 : FontWeight.normal,
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
