import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../budget/domain/monthly_budget.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';
import 'expense_category_ui.dart';
import 'expense_form_sheet.dart';
import 'expenses_provider.dart';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

class ExpensesPage extends ConsumerWidget {
  const ExpensesPage({super.key});

  void _openExpenseForm(BuildContext context, {Expense? expense}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return ExpenseFormSheet(expense: expense);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(currentMonthExpensesProvider);

    final total = ref.watch(currentMonthExpensesTotalProvider);

    final categoryTotals = ref.watch(currentMonthExpensesByCategoryProvider);

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gastos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openExpenseForm(context);
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: expenses.isEmpty
            ? _EmptyExpenses(
                onAdd: () {
                  _openExpenseForm(context);
                },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MES ACTUAL
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.calendar_month_outlined,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Gastos del mes',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                MonthlyBudget.currentPeriodLabel(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TOTAL GASTADO
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Total gastado',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 7),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _moneyFormat.format(total),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${expenses.length} '
                            '${expenses.length == 1 ? 'gasto registrado' : 'gastos registrados'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // RESUMEN DE CATEGORÍAS
                    if (sortedCategories.isNotEmpty) ...[
                      const Text(
                        'Por categoría',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            for (final entry in sortedCategories)
                              _CategorySummaryRow(
                                category: entry.key,
                                amount: entry.value,
                                total: total,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                    ],

                    // LISTA DE GASTOS
                    const Text(
                      'Mis gastos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Text(
                      'Toca un gasto para editarlo o eliminarlo.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 14),

                    for (final expense in expenses)
                      _ExpenseCard(
                        expense: expense,
                        onTap: () {
                          _openExpenseForm(context, expense: expense);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ====================================================
// SIN GASTOS
// ====================================================

class _EmptyExpenses extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyExpenses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 42,
                color: AppColors.primaryDark,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              MonthlyBudget.currentPeriodLabel(),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Todavía no tienes gastos',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Agrega tu primer gasto del mes para comenzar a controlar tu presupuesto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar gasto'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================
// RESUMEN DE CATEGORÍA
// ====================================================

class _CategorySummaryRow extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double total;

  const _CategorySummaryRow({
    required this.category,
    required this.amount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final categoryColor = expenseCategoryColor(category);

    final percentage = total <= 0 ? 0.0 : (amount / total) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              expenseCategoryIcon(category),
              color: categoryColor,
              size: 21,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${percentage.toStringAsFixed(1)}% del total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            _moneyFormat.format(amount),
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

// ====================================================
// TARJETA DE GASTO
// ====================================================

class _ExpenseCard extends StatelessWidget {
  final Expense expense;
  final VoidCallback onTap;

  const _ExpenseCard({required this.expense, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(expense.date);

    final categoryColor = expenseCategoryColor(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),

        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: categoryColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            expenseCategoryIcon(expense.category),
            color: categoryColor,
          ),
        ),

        title: Text(
          expense.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            '${expense.category.label} • $formattedDate',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _moneyFormat.format(expense.amount),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
