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

class ExpensesPage extends ConsumerStatefulWidget {
  const ExpensesPage({super.key});

  @override
  ConsumerState<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends ConsumerState<ExpensesPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DateTime _defaultDateForMonth(DateTime selectedMonth) {
    final now = DateTime.now();

    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      return now;
    }

    final lastDay = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final day = now.day > lastDay ? lastDay : now.day;

    return DateTime(selectedMonth.year, selectedMonth.month, day);
  }

  void _openExpenseForm({Expense? expense}) {
    final selectedMonth = ref.read(expenseFilterProvider).selectedMonth;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return ExpenseFormSheet(
          expense: expense,
          initialDate: expense == null
              ? _defaultDateForMonth(selectedMonth)
              : null,
        );
      },
    );
  }

  bool _isCurrentMonth(DateTime selectedMonth) {
    final now = DateTime.now();

    return selectedMonth.year == now.year && selectedMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(expenseFilterProvider);

    final monthExpenses = ref.watch(selectedMonthExpensesProvider);

    final visibleExpenses = ref.watch(filteredExpensesProvider);

    final total = ref.watch(selectedMonthExpensesTotalProvider);

    final categoryTotals = ref.watch(selectedMonthExpensesByCategoryProvider);

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final isCurrentMonth = _isCurrentMonth(filter.selectedMonth);

    return Scaffold(
      appBar: AppBar(title: const Text('Gastos')),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _openExpenseForm();
        },
        child: const Icon(Icons.add),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =====================================
              // SELECTOR DEL MES
              // =====================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Mes anterior',
                      onPressed: () {
                        ref
                            .read(expenseFilterProvider.notifier)
                            .previousMonth();
                      },
                      icon: const Icon(Icons.chevron_left),
                    ),

                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Gastos del mes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            MonthlyBudget.formatPeriod(
                              month: filter.selectedMonth.month,
                              year: filter.selectedMonth.year,
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      tooltip: 'Mes siguiente',
                      onPressed: isCurrentMonth
                          ? null
                          : () {
                              ref
                                  .read(expenseFilterProvider.notifier)
                                  .nextMonth();
                            },
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              if (!isCurrentMonth) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      ref
                          .read(expenseFilterProvider.notifier)
                          .goToCurrentMonth();
                    },
                    icon: const Icon(Icons.today_outlined, size: 18),
                    label: const Text('Volver al mes actual'),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // =====================================
              // TOTAL DEL MES
              // =====================================
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
                      style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      '${monthExpenses.length} '
                      '${monthExpenses.length == 1 ? 'gasto registrado' : 'gastos registrados'}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // =====================================
              // RESUMEN DE CATEGORÍAS
              // =====================================
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

              // =====================================
              // BUSCADOR
              // =====================================
              const Text(
                'Mis gastos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _searchController,
                onChanged: (value) {
                  ref.read(expenseFilterProvider.notifier).setSearch(value);
                },
                decoration: InputDecoration(
                  hintText: 'Buscar gasto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: filter.searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpiar búsqueda',
                          onPressed: () {
                            _searchController.clear();

                            ref
                                .read(expenseFilterProvider.notifier)
                                .setSearch('');
                          },
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // =====================================
              // FILTROS DE CATEGORÍA
              // =====================================
              const Text(
                'Categoría',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('Todas'),
                        selected: filter.category == null,
                        onSelected: (_) {
                          ref
                              .read(expenseFilterProvider.notifier)
                              .setCategory(null);
                        },
                      ),
                    ),

                    for (final category in ExpenseCategory.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Icon(expenseCategoryIcon(category), size: 17),
                          label: Text(category.label),
                          selected: filter.category == category,
                          onSelected: (_) {
                            ref
                                .read(expenseFilterProvider.notifier)
                                .setCategory(category);
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // =====================================
              // ORDENAMIENTO
              // =====================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.sort,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),

                    const SizedBox(width: 10),

                    const Expanded(
                      child: Text(
                        'Ordenar por',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),

                    PopupMenuButton<ExpenseSortOrder>(
                      initialValue: filter.sortOrder,
                      onSelected: (order) {
                        ref
                            .read(expenseFilterProvider.notifier)
                            .setSortOrder(order);
                      },
                      itemBuilder: (context) {
                        return [
                          for (final order in ExpenseSortOrder.values)
                            PopupMenuItem(
                              value: order,
                              child: Text(order.label),
                            ),
                        ];
                      },
                      child: Row(
                        children: [
                          Text(
                            filter.sortOrder.label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // =====================================
              // RESULTADOS
              // =====================================
              if (monthExpenses.isEmpty)
                _EmptyMonthExpenses(
                  onAdd: () {
                    _openExpenseForm();
                  },
                )
              else if (visibleExpenses.isEmpty)
                const _NoFilterResults()
              else ...[
                Text(
                  '${visibleExpenses.length} '
                  '${visibleExpenses.length == 1 ? 'resultado' : 'resultados'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 10),

                for (final expense in visibleExpenses)
                  _ExpenseCard(
                    expense: expense,
                    onTap: () {
                      _openExpenseForm(expense: expense);
                    },
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================
// CATEGORÍA
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
        trailing: Text(
          _moneyFormat.format(expense.amount),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ====================================================
// MES SIN GASTOS
// ====================================================

class _EmptyMonthExpenses extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyMonthExpenses({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: AppColors.primaryDark,
          ),

          const SizedBox(height: 14),

          const Text(
            'No hay gastos en este mes',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Puedes registrar un gasto para el periodo seleccionado.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Agregar gasto'),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// FILTROS SIN RESULTADOS
// ====================================================

class _NoFilterResults extends StatelessWidget {
  const _NoFilterResults();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 38,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'No se encontraron gastos',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Prueba con otro nombre o categoría.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
