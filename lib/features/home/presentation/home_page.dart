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
    // 1. Cerrar sesión real de Firebase.
    await ref.read(authRepositoryProvider).signOut();

    // 2. Limpiar gastos almacenados temporalmente en memoria.
    ref.invalidate(expensesProvider);
    ref.invalidate(expenseFilterProvider);

    // 3. Limpiar pagos almacenados temporalmente en memoria.
    ref.invalidate(paymentRepositoryProvider);
    ref.invalidate(paymentsProvider);

    // 4. Limpiar presupuesto almacenado temporalmente.
    ref.invalidate(budgetProvider);

    if (!context.mounted) {
      return;
    }

    // 5. Regresar al Login.
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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);

    final spent = ref.watch(currentMonthExpensesTotalProvider);

    final expenses = ref.watch(currentMonthExpensesProvider);

    final payments = ref.watch(paymentsProvider);

    final nearestPayment = _getNearestPayment(payments);

    if (budget == null) {
      return _HomeWithoutBudget(
        expenses: expenses,
        nearestPayment: nearestPayment,
      );
    }

    final available = budget - spent;

    final signal = BudgetSignal.from(budget: budget, spent: spent);

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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ENCABEZADO
              // ==================================================
              const _FinancialHeader(),

              const SizedBox(height: 20),

              // ==================================================
              // ALERTA DEL SEMÁFORO
              // ==================================================
              if (signal.status != BudgetSignalStatus.healthy) ...[
                _BudgetAlert(signal: signal),
                const SizedBox(height: 18),
              ],

              // ==================================================
              // TARJETA PRINCIPAL
              // ==================================================
              _BudgetStatusCard(
                budget: budget,
                spent: spent,
                available: available,
                signal: signal,
              ),

              const SizedBox(height: 20),

              // ==================================================
              // PROGRESO
              // ==================================================
              _BudgetProgressCard(spent: spent, signal: signal),

              const SizedBox(height: 26),

              // ==================================================
              // RESUMEN
              // ==================================================
              const Text(
                'Resumen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.payments_outlined,
                      title: 'Gastado',
                      value: _moneyFormat.format(spent),
                      accentColor: signal.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Presupuesto',
                      value: _moneyFormat.format(budget),
                      accentColor: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 26),

              // ==================================================
              // PRÓXIMO PAGO
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Próximo pago',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(AppRoutes.payments);
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              if (nearestPayment == null)
                const _NoUpcomingPayment()
              else
                _UpcomingPaymentCard(payment: nearestPayment),

              const SizedBox(height: 26),

              // ==================================================
              // GASTOS RECIENTES
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gastos recientes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(AppRoutes.expenses);
                    },
                    child: const Text('Ver todos'),
                  ),
                ],
              ),

              const SizedBox(height: 8),

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
// ENCABEZADO
// ====================================================

class _FinancialHeader extends StatelessWidget {
  const _FinancialHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.calendar_month_outlined,
                  size: 18,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                MonthlyBudget.currentPeriodLabel(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Resumen financiero',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Consulta el estado de tu presupuesto y tus gastos del mes.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// TARJETA PRINCIPAL
// ====================================================

class _BudgetStatusCard extends StatelessWidget {
  final double budget;
  final double spent;
  final double available;
  final BudgetSignal signal;

  const _BudgetStatusCard({
    required this.budget,
    required this.spent,
    required this.available,
    required this.signal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: signal.softColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: signal.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: signal.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: signal.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  signal.label,
                  style: TextStyle(
                    color: signal.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          Text(
            available >= 0 ? 'Disponible' : 'Presupuesto excedido',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 7),

          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _moneyFormat.format(available.abs()),
              style: TextStyle(
                color: signal.primaryColor,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Presupuesto: ${_moneyFormat.format(budget)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            signal.message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// PROGRESO
// ====================================================

class _BudgetProgressCard extends StatelessWidget {
  final double spent;
  final BudgetSignal signal;

  const _BudgetProgressCard({required this.spent, required this.signal});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Presupuesto mensual',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                MonthlyBudget.currentPeriodLabel(),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LinearProgressIndicator(
            value: signal.progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: AppColors.border,
            color: signal.primaryColor,
          ),

          const SizedBox(height: 14),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Gastado: ${_moneyFormat.format(spent)}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${signal.percentageUsed.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: signal.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ====================================================
// ALERTA
// ====================================================

class _BudgetAlert extends StatelessWidget {
  final BudgetSignal signal;

  const _BudgetAlert({required this.signal});

  @override
  Widget build(BuildContext context) {
    final IconData icon = switch (signal.status) {
      BudgetSignalStatus.healthy => Icons.check_circle_outline,
      BudgetSignalStatus.warning => Icons.notifications_active_outlined,
      BudgetSignalStatus.danger => Icons.warning_amber_rounded,
      BudgetSignalStatus.exceeded => Icons.error_outline,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: signal.softColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: signal.primaryColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: signal.primaryColor, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signal.label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: signal.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  signal.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
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
// RESUMEN
// ====================================================

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color accentColor;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// HOME SIN PRESUPUESTO
// ====================================================

class _HomeWithoutBudget extends ConsumerWidget {
  final List<Expense> expenses;
  final Payment? nearestPayment;

  const _HomeWithoutBudget({
    required this.expenses,
    required this.nearestPayment,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _FinancialHeader(),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 32,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Configura tu presupuesto mensual',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Define cuánto dinero deseas administrar durante este mes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          context.go(AppRoutes.budget);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Ingresar presupuesto'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'Próximo pago',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              if (nearestPayment == null)
                const _NoUpcomingPayment()
              else
                _UpcomingPaymentCard(payment: nearestPayment!),

              const SizedBox(height: 26),

              const Text(
                'Gastos recientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(14),
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
// GASTOS RECIENTES
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
        borderRadius: BorderRadius.circular(14),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 36,
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
