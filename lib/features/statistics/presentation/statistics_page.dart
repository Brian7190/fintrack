import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../budget/presentation/budget_provider.dart';
import '../../expenses/domain/expense_category.dart';
import '../../expenses/presentation/expense_category_ui.dart';
import '../../expenses/presentation/expenses_provider.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(budgetProvider);
    final expenses = ref.watch(expensesProvider);
    final totalSpent = ref.watch(totalExpensesProvider);
    final categoryTotals = ref.watch(expensesByCategoryProvider);

    final average = expenses.isEmpty ? 0.0 : totalSpent / expenses.length;

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = sortedCategories.isEmpty
        ? null
        : sortedCategories.first;

    final available = budget == null ? null : budget - totalSpent;

    final percentageUsed = budget == null || budget <= 0
        ? 0.0
        : (totalSpent / budget) * 100;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: expenses.isEmpty
            ? const _EmptyStatistics()
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resumen financiero',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Analiza cómo estás distribuyendo tus gastos.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 24),

                    // RESUMEN PRINCIPAL
                    _MainSummaryCard(
                      totalSpent: totalSpent,
                      budget: budget,
                      available: available,
                      percentageUsed: percentageUsed,
                    ),

                    const SizedBox(height: 20),

                    // PROMEDIO Y CATEGORÍA PRINCIPAL
                    Row(
                      children: [
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.calculate_outlined,
                            title: 'Promedio',
                            value: '\$${average.toStringAsFixed(2)}',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatisticCard(
                            icon: Icons.trending_up,
                            title: 'Mayor categoría',
                            value: topCategory == null
                                ? '-'
                                : topCategory.key.label,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Distribución por categoría',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _CategoryPieChart(
                      categoryTotals: categoryTotals,
                      totalSpent: totalSpent,
                    ),

                    const SizedBox(height: 26),

                    const Text(
                      'Gasto por categoría',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _CategoryBarChart(categoryTotals: categoryTotals),

                    const SizedBox(height: 26),

                    const Text(
                      'Detalle por categoría',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    for (final entry in sortedCategories)
                      _CategoryDetailCard(
                        category: entry.key,
                        amount: entry.value,
                        totalSpent: totalSpent,
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

// ----------------------------------------------------
// RESUMEN PRINCIPAL
// ----------------------------------------------------

class _MainSummaryCard extends StatelessWidget {
  final double totalSpent;
  final double? budget;
  final double? available;
  final double percentageUsed;

  const _MainSummaryCard({
    required this.totalSpent,
    required this.budget,
    required this.available,
    required this.percentageUsed,
  });

  @override
  Widget build(BuildContext context) {
    final bool overBudget = budget != null && totalSpent > budget!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total gastado',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            '\$${totalSpent.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          if (budget == null)
            const Text(
              'Configura un presupuesto para obtener un análisis más completo.',
              style: TextStyle(color: Colors.white70),
            )
          else ...[
            _SummaryLine(
              title: 'Presupuesto',
              value: '\$${budget!.toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            _SummaryLine(
              title: overBudget ? 'Excedido' : 'Disponible',
              value: '\$${available!.abs().toStringAsFixed(2)}',
            ),
            const SizedBox(height: 8),
            Text(
              '${percentageUsed.toStringAsFixed(1)}% del presupuesto utilizado',
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final String title;
  final String value;

  const _SummaryLine({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white70)),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// TARJETAS PEQUEÑAS
// ----------------------------------------------------

class _StatisticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatisticCard({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// GRÁFICA CIRCULAR POR CATEGORÍA
// ----------------------------------------------------

class _CategoryPieChart extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryTotals;
  final double totalSpent;

  const _CategoryPieChart({
    required this.categoryTotals,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final entries = categoryTotals.entries
        .where((entry) => entry.value > 0)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 48,
                sectionsSpace: 3,
                sections: [
                  for (final entry in entries)
                    PieChartSectionData(
                      value: entry.value,
                      color: expenseCategoryColor(entry.key),
                      radius: 52,
                      title: totalSpent <= 0
                          ? ''
                          : '${((entry.value / totalSpent) * 100).toStringAsFixed(0)}%',
                      titleStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          Wrap(
            alignment: WrapAlignment.center,
            spacing: 14,
            runSpacing: 10,
            children: [
              for (final entry in entries)
                _LegendItem(
                  color: expenseCategoryColor(entry.key),
                  text: entry.key.label,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// GRÁFICA DE BARRAS POR CATEGORÍA
// ----------------------------------------------------

class _CategoryBarChart extends StatelessWidget {
  final Map<ExpenseCategory, double> categoryTotals;

  const _CategoryBarChart({required this.categoryTotals});

  @override
  Widget build(BuildContext context) {
    final entries =
        categoryTotals.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final double highest = entries.fold<double>(
      0,
      (current, entry) => entry.value > current ? entry.value : current,
    );

    final maxY = highest <= 0 ? 100.0 : highest * 1.25;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 22, 14, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 230,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                alignment: BarChartAlignment.spaceAround,
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();

                        if (index < 0 || index >= entries.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (int index = 0; index < entries.length; index++)
                    BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entries[index].value,
                          width: 24,
                          color: expenseCategoryColor(entries[index].key),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          for (int index = 0; index < entries.length; index++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: expenseCategoryColor(
                        entries[index].key,
                      ).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: expenseCategoryColor(entries[index].key),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(entries[index].key.label)),
                  Text(
                    '\$${entries[index].value.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// DETALLE DE CATEGORÍA
// ----------------------------------------------------

class _CategoryDetailCard extends StatelessWidget {
  final ExpenseCategory category;
  final double amount;
  final double totalSpent;

  const _CategoryDetailCard({
    required this.category,
    required this.amount,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalSpent <= 0 ? 0.0 : (amount / totalSpent) * 100;

    final categoryColor = expenseCategoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: categoryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(expenseCategoryIcon(category), color: categoryColor),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  '${percentage.toStringAsFixed(1)}% del total gastado',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// LEYENDA
// ----------------------------------------------------

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;

  const _LegendItem({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// SIN ESTADÍSTICAS
// ----------------------------------------------------

class _EmptyStatistics extends StatelessWidget {
  const _EmptyStatistics();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFE9F6EF),
              child: Icon(
                Icons.bar_chart_outlined,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Aún no hay estadísticas',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Registra algunos gastos y aquí podrás analizar cómo distribuyes tu dinero por categorías.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
