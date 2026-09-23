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

  bool _isSaving = false;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  // ====================================================
  // GUARDAR PRESUPUESTO
  // ====================================================

  Future<void> _saveBudget() async {
    if (_isSaving) {
      return;
    }

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

    // ==================================================
    // ADVERTENCIA
    // ==================================================

    if (amount < spent) {
      final difference = spent - amount;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            icon: Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: AppColors.warningSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 30,
              ),
            ),
            title: const Text('Presupuesto menor a tus gastos'),
            content: Text(
              'Ya has gastado '
              '${_moneyFormat.format(spent)} '
              'este mes.\n\n'
              'Si estableces un presupuesto de '
              '${_moneyFormat.format(amount)}, '
              'tu saldo será '
              '${_moneyFormat.format(-difference)}.\n\n'
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

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(budgetStateProvider.notifier).saveBudget(amount);

      _budgetController.clear();

      if (!mounted) {
        return;
      }

      FocusScope.of(context).unfocus();

      _showMessage('Presupuesto guardado correctamente');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error.toString();

      if (message.contains('permission-denied')) {
        _showMessage('No tienes permiso para guardar este presupuesto.');
        return;
      }

      if (message.contains('No existe un usuario autenticado')) {
        _showMessage('Tu sesión ya no está activa. Inicia sesión nuevamente.');
        return;
      }

      _showMessage('No fue posible guardar el presupuesto.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
              // ==================================================
              // PERIODO
              // ==================================================
              _PeriodHeader(period: MonthlyBudget.currentPeriodLabel()),

              const SizedBox(height: 20),

              // ==================================================
              // PRESUPUESTO
              // ==================================================
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

              // ==================================================
              // AVISO
              // ==================================================
              if (isOverBudget) ...[
                const SizedBox(height: 16),

                _ExceededBudgetAlert(exceededAmount: spent - budget),
              ],

              const SizedBox(height: 28),

              // ==================================================
              // FORMULARIO
              // ==================================================
              _BudgetFormCard(
                controller: _budgetController,
                hasBudget: budget != null,
                isSaving: _isSaving,
                onSave: _saveBudget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ====================================================
// PERIODO
// ====================================================

class _PeriodHeader extends StatelessWidget {
  final String period;

  const _PeriodHeader({required this.period});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Text(
                  'Presupuesto del mes',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  period,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
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
// SIN PRESUPUESTO
// ====================================================

class _NoBudgetCard extends StatelessWidget {
  final double spent;

  const _NoBudgetCard({required this.spent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 7),
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
            'Aún no tienes un presupuesto',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 7),

          const Text(
            'Define cuánto dinero deseas administrar durante este mes.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
          ),

          if (spent > 0) ...[
            const SizedBox(height: 22),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.white70,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ya gastaste este mes',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _moneyFormat.format(spent),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ====================================================
// RESUMEN DEL PRESUPUESTO
// ====================================================

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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.17),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 23,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  isOverBudget ? 'Presupuesto excedido' : 'Presupuesto mensual',
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
                    color: AppColors.error,
                    size: 17,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'LÍMITE SUPERADO',
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
          // PRESUPUESTO
          // ==================================================
          const Text(
            'Presupuesto',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),

          const SizedBox(height: 4),

          Text(
            _moneyFormat.format(budget),
            style: const TextStyle(
              fontSize: 32,
              height: 1,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 24),

          // ==================================================
          // BARRA
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

          const SizedBox(height: 10),

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
                    : 'Dentro del límite',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(height: 22),

          // ==================================================
          // MÉTRICAS
          // ==================================================
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _DarkMetric(
                    label: 'Gastado',
                    value: _moneyFormat.format(spent),
                  ),
                ),

                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.18),
                ),

                Expanded(
                  child: _DarkMetric(
                    label: isOverBudget ? 'Saldo' : 'Disponible',
                    value: _moneyFormat.format(available),
                    isNegative: isOverBudget,
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
// MÉTRICA OSCURA
// ====================================================

class _DarkMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isNegative;

  const _DarkMetric({
    required this.label,
    required this.value,
    this.isNegative = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 11),
        ),

        const SizedBox(height: 5),

        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: isNegative ? const Color(0xFFFFC7C2) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ],
    );
  }
}

// ====================================================
// ALERTA
// ====================================================

class _ExceededBudgetAlert extends StatelessWidget {
  final double exceededAmount;

  const _ExceededBudgetAlert({required this.exceededAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: AppColors.error),
          ),

          const SizedBox(width: 13),

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
                  'Has superado tu presupuesto por '
                  '${_moneyFormat.format(exceededAmount)}.',
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
// FORMULARIO
// ====================================================

class _BudgetFormCard extends StatelessWidget {
  final TextEditingController controller;
  final bool hasBudget;
  final bool isSaving;
  final Future<void> Function() onSave;

  const _BudgetFormCard({
    required this.controller,
    required this.hasBudget,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasBudget ? 'Actualizar presupuesto' : 'Ingresa tu presupuesto',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            hasBudget
                ? 'Puedes modificarlo si tus planes financieros cambian.'
                : 'Define cuánto deseas gastar durante este mes.',
            style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
          ),

          const SizedBox(height: 18),

          TextField(
            controller: controller,
            enabled: !isSaving,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
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
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                isSaving
                    ? 'Guardando...'
                    : hasBudget
                    ? 'Actualizar presupuesto'
                    : 'Crear presupuesto',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
