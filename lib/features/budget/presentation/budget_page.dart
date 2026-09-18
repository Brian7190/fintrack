import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../expenses/presentation/expenses_provider.dart';
import '../domain/monthly_budget.dart';
import 'budget_provider.dart';

final NumberFormat _moneyFormat = NumberFormat.currency(
  locale: 'es_MX',
  symbol: '\$',
  decimalDigits: 2,
);

class BudgetPage extends ConsumerStatefulWidget {
  const BudgetPage({super.key});

  @override
  ConsumerState<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends ConsumerState<BudgetPage> {
  final TextEditingController _budgetController = TextEditingController();

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _saveBudget() async {
    final text = _budgetController.text.trim().replaceAll(',', '.');

    if (text.isEmpty) {
      _showMessage('Ingresa un presupuesto');
      return;
    }

    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      _showMessage('Ingresa una cantidad válida');
      return;
    }

    final spent = ref.read(currentMonthExpensesTotalProvider);

    // ADVERTENCIA CUANDO EL PRESUPUESTO ES MENOR
    // A LO QUE YA SE HA GASTADO.
    if (amount < spent) {
      final difference = spent - amount;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.warning,
              size: 38,
            ),
            title: const Text('Presupuesto menor a tus gastos'),
            content: Text(
              'Ya has gastado '
              '${_moneyFormat.format(spent)} '
              'este mes.\n\n'
              'Si estableces un presupuesto de '
              '${_moneyFormat.format(amount)}, '
              'lo excederás por '
              '${_moneyFormat.format(difference)}.\n\n'
              '¿Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(false);
                },
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop(true);
                },
                child: const Text('Continuar'),
              ),
            ],
          );
        },
      );

      if (!mounted || confirm != true) {
        return;
      }
    }

    ref.read(budgetStateProvider.notifier).saveBudget(amount);

    _budgetController.clear();

    if (!mounted) {
      return;
    }

    FocusScope.of(context).unfocus();

    _showMessage('Presupuesto guardado correctamente');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final currentBudget = ref.watch(currentBudgetProvider);

    final spent = ref.watch(currentMonthExpensesTotalProvider);

    final budget = currentBudget?.amount;

    final available = budget == null ? null : budget - spent;

    final percentageUsed = budget == null || budget <= 0
        ? 0.0
        : (spent / budget) * 100;

    final progress = budget == null || budget <= 0
        ? 0.0
        : (spent / budget).clamp(0.0, 1.0).toDouble();

    final isOverBudget = budget != null && spent > budget;

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuesto')),
      body: SafeArea(
        child: SingleChildScrollView(
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
                          'Presupuesto del mes',
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

              if (budget == null)
                _NoBudgetCard(spent: spent)
              else
                _BudgetSummaryCard(
                  budget: budget,
                  spent: spent,
                  available: available!,
                  percentageUsed: percentageUsed,
                  progress: progress,
                  isOverBudget: isOverBudget,
                ),

              const SizedBox(height: 28),

              Text(
                budget == null
                    ? 'Ingresa tu presupuesto'
                    : 'Actualizar presupuesto',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                budget == null
                    ? 'Define cuánto deseas gastar durante este mes.'
                    : 'Puedes ajustar tu presupuesto si tus planes cambian.',
                style: const TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej. 10000.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveBudget,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(
                    budget == null
                        ? 'Crear presupuesto'
                        : 'Actualizar presupuesto',
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================================================
// SIN PRESUPUESTO
// ==================================================

class _NoBudgetCard extends StatelessWidget {
  final double spent;

  const _NoBudgetCard({required this.spent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: AppColors.primaryDark,
          ),

          const SizedBox(height: 14),

          const Text(
            'Aún no tienes un presupuesto',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Establece cuánto dinero deseas administrar durante este mes.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),

          if (spent > 0) ...[
            const SizedBox(height: 18),

            const Divider(),

            const SizedBox(height: 12),

            const Text(
              'Ya gastaste este mes',
              style: TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 4),

            Text(
              _moneyFormat.format(spent),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ==================================================
// RESUMEN DE PRESUPUESTO
// ==================================================

class _BudgetSummaryCard extends StatelessWidget {
  final double budget;
  final double spent;
  final double available;
  final double percentageUsed;
  final double progress;
  final bool isOverBudget;

  const _BudgetSummaryCard({
    required this.budget,
    required this.spent,
    required this.available,
    required this.percentageUsed,
    required this.progress,
    required this.isOverBudget,
  });

  @override
  Widget build(BuildContext context) {
    final indicatorColor = isOverBudget
        ? AppColors.error
        : percentageUsed >= 80
        ? AppColors.warning
        : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Presupuesto mensual',
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 5),

          Text(
            _moneyFormat.format(budget),
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 22),

          LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            borderRadius: BorderRadius.circular(10),
            backgroundColor: AppColors.border,
            color: indicatorColor,
          ),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${percentageUsed.toStringAsFixed(1)}% utilizado',
                style: TextStyle(
                  color: indicatorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                isOverBudget ? 'Excedido' : 'Disponible',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: _BudgetMetric(
                  label: 'Gastado',
                  value: _moneyFormat.format(spent),
                ),
              ),

              Container(height: 42, width: 1, color: AppColors.border),

              Expanded(
                child: _BudgetMetric(
                  label: isOverBudget ? 'Excedido por' : 'Disponible',
                  value: _moneyFormat.format(available.abs()),
                  valueColor: isOverBudget
                      ? AppColors.error
                      : AppColors.primaryDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BudgetMetric({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 5),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
