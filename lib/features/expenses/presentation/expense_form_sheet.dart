import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';
import 'expense_category_ui.dart';
import 'expenses_provider.dart';

class ExpenseFormSheet extends ConsumerStatefulWidget {
  final Expense? expense;

  // Fecha inicial utilizada cuando estamos creando
  // un gasto desde un mes anterior.
  final DateTime? initialDate;

  const ExpenseFormSheet({super.key, this.expense, this.initialDate});

  @override
  ConsumerState<ExpenseFormSheet> createState() => _ExpenseFormSheetState();
}

class _ExpenseFormSheetState extends ConsumerState<ExpenseFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  late ExpenseCategory _selectedCategory;
  late DateTime _selectedDate;

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

    _selectedDate =
        widget.expense?.date ?? widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();

    super.dispose();
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
      helpText: 'Selecciona la fecha del gasto',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (!mounted || date == null) {
      return;
    }

    setState(() {
      _selectedDate = date;
    });
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
            date: _selectedDate,
          );
    } else {
      ref
          .read(expensesProvider.notifier)
          .addExpense(
            name: name,
            amount: amount,
            category: _selectedCategory,
            date: _selectedDate,
          );
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
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

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

              // NOMBRE
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
                  hintText: 'Ej. Supermercado',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // MONTO
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

              // CATEGORÍA
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

              const SizedBox(height: 16),

              // FECHA
              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del gasto',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    suffixIcon: Icon(Icons.chevron_right),
                  ),
                  child: Text(formattedDate),
                ),
              ),

              const SizedBox(height: 24),

              // GUARDAR
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
                    icon: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                    label: const Text(
                      'Eliminar gasto',
                      style: TextStyle(color: AppColors.error),
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
