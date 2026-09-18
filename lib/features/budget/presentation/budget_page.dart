import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import 'budget_provider.dart';

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

  void _saveBudget() {
    final text = _budgetController.text.trim();

    if (text.isEmpty) {
      _showMessage('Ingresa un presupuesto');
      return;
    }

    final amount = double.tryParse(text);

    if (amount == null || amount <= 0) {
      _showMessage('Ingresa una cantidad válida');
      return;
    }

    ref.read(budgetProvider.notifier).updateBudget(amount);

    _budgetController.clear();
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
    final budget = ref.watch(budgetProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Presupuesto',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Presupuesto mensual',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Define cuánto dinero deseas utilizar durante este mes.',
                style: TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              if (budget == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F6EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Aún no tienes un presupuesto',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Ingresa tu presupuesto de este mes para comenzar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              else
                Container(
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
                        'Presupuesto actual',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${budget.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              Text(
                budget == null
                    ? 'Ingresa tu presupuesto'
                    : 'Cambiar presupuesto',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Cantidad',
                  hintText: 'Ej. 10000',
                  prefixIcon: const Icon(Icons.attach_money),
                  helperText: budget == null
                      ? 'Este será tu presupuesto mensual inicial.'
                      : 'Puedes modificarlo cuando lo necesites.',
                ),
              ),

              const SizedBox(height: 20),

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
            ],
          ),
        ),
      ),
    );
  }
}
