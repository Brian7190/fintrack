import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/expense.dart';
import '../domain/expense_category.dart';
import 'expense_category_ui.dart';
import 'expenses_provider.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final Expense? expense;

  const ExpenseFormSheet({super.key, this.expense});

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  late ExpenseCategory _selectedCategory;

  bool get isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.expense?.name ?? '');

    _amountController = TextEditingController(
      text: widget.expense == null
          ? ''
          : widget.expense!.amount.toStringAsFixed(2),
    );

    _selectedCategory = widget.expense?.category ?? ExpenseCategory.other;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  void _save() {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid) {
      return;
    }

    final name = _nameController.text.trim();

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    if (isEditing) {
      ref
          .read(expensesProvider.notifier)
          .updateExpense(
            id: widget.expense!.id,
            name: name,
            amount: amount,
            category: _selectedCategory,
          );
    } else {
      ref
          .read(expensesProvider.notifier)
          .addExpense(name: name, amount: amount, category: _selectedCategory);
    }

    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final expense = widget.expense;

    if (expense == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar gasto'),
          content: Text('¿Deseas eliminar "${expense.name}"?'),
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
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirm != true) {
      return;
    }

    ref.read(expensesProvider.notifier).deleteExpense(expense.id);

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Editar gasto' : 'Nuevo gasto',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del gasto';
                  }

                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Nombre del gasto',
                  hintText: 'Ej. Comida',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                validator: (value) {
                  final text = value?.replaceAll(',', '.') ?? '';

                  final amount = double.tryParse(text);

                  if (text.isEmpty) {
                    return 'Ingresa el monto';
                  }

                  if (amount == null || amount <= 0) {
                    return 'Ingresa un monto válido';
                  }

                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  hintText: 'Ej. 250.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          expenseCategoryIcon(category),
                          color: expenseCategoryColor(category),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(category.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (category) {
                  if (category == null) {
                    return;
                  }

                  setState(() {
                    _selectedCategory = category;
                  });
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? 'Guardar cambios' : 'Agregar gasto'),
                ),
              ),

              if (isEditing) ...[
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    label: const Text(
                      'Eliminar gasto',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
