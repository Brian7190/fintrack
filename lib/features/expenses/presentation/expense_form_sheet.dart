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

  bool _isSaving = false;
  bool _isDeleting = false;

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

  // ====================================================
  // SELECCIONAR FECHA
  // ====================================================

  Future<void> _selectDate() async {
    if (_isSaving || _isDeleting) {
      return;
    }

    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: now,
      helpText: 'Selecciona la fecha del gasto',
      cancelText: 'Cancelar',
      confirmText: 'Seleccionar',
    );

    if (!mounted || selectedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = selectedDate;
    });
  }

  // ====================================================
  // GUARDAR
  // ====================================================

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || _isSaving || _isDeleting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final name = _nameController.text.trim();

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    setState(() {
      _isSaving = true;
    });

    try {
      if (isEditing) {
        await ref
            .read(expensesProvider.notifier)
            .updateExpense(
              id: widget.expense!.id,
              name: name,
              amount: amount,
              category: _selectedCategory,
              date: _selectedDate,
            );
      } else {
        await ref
            .read(expensesProvider.notifier)
            .addExpense(
              name: name,
              amount: amount,
              category: _selectedCategory,
              date: _selectedDate,
            );
      }

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Gasto actualizado correctamente'
                : 'Gasto agregado correctamente',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyFirebaseError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ====================================================
  // ELIMINAR
  // ====================================================

  Future<void> _delete() async {
    final expense = widget.expense;

    if (expense == null || _isSaving || _isDeleting) {
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

    setState(() {
      _isDeleting = true;
    });

    try {
      await ref.read(expensesProvider.notifier).deleteExpense(expense.id);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);

      Navigator.of(context).pop();

      messenger.showSnackBar(
        const SnackBar(content: Text('Gasto eliminado correctamente')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_friendlyFirebaseError(error))));
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ====================================================
  // MENSAJES DE ERROR
  // ====================================================

  String _friendlyFirebaseError(Object error) {
    final message = error.toString();

    if (message.contains('permission-denied')) {
      return 'No tienes permiso para modificar este gasto.';
    }

    if (message.contains('network')) {
      return 'No fue posible conectarse a Firebase. Revisa tu conexión.';
    }

    if (message.contains('No existe un usuario autenticado')) {
      return 'Tu sesión ya no está activa. Inicia sesión nuevamente.';
    }

    return 'No fue posible completar la operación. Inténtalo nuevamente.';
  }

  // ====================================================
  // INTERFAZ
  // ====================================================

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd/MM/yyyy').format(_selectedDate);

    final isWorking = _isSaving || _isDeleting;

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
              // ==================================================
              // ENCABEZADO
              // ==================================================
              Text(
                isEditing ? 'Editar gasto' : 'Nuevo gasto',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                isEditing
                    ? 'Modifica la información del gasto.'
                    : 'Registra un nuevo movimiento en tus finanzas.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 22),

              // ==================================================
              // NOMBRE
              // ==================================================
              TextFormField(
                controller: _nameController,
                enabled: !isWorking,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Ingresa el nombre del gasto';
                  }

                  if (name.length < 2) {
                    return 'Ingresa un nombre válido';
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

              // ==================================================
              // MONTO
              // ==================================================
              TextFormField(
                controller: _amountController,
                enabled: !isWorking,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d{0,2}'),
                  ),
                ],
                validator: (value) {
                  final text = value?.replaceAll(',', '.').trim() ?? '';

                  if (text.isEmpty) {
                    return 'Ingresa el monto';
                  }

                  final amount = double.tryParse(text);

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

              // ==================================================
              // CATEGORÍA
              // ==================================================
              DropdownButtonFormField<ExpenseCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: ExpenseCategory.values.map((category) {
                  return DropdownMenuItem<ExpenseCategory>(
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
                onChanged: isWorking
                    ? null
                    : (category) {
                        if (category == null) {
                          return;
                        }

                        setState(() {
                          _selectedCategory = category;
                        });
                      },
              ),

              const SizedBox(height: 16),

              // ==================================================
              // FECHA
              // ==================================================
              InkWell(
                onTap: isWorking ? null : _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha del gasto',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    suffixIcon: Icon(Icons.chevron_right),
                  ),
                  child: Text(
                    formattedDate,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // GUARDAR
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: isWorking ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.3,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(
                    _isSaving
                        ? 'Guardando...'
                        : isEditing
                        ? 'Guardar cambios'
                        : 'Agregar gasto',
                  ),
                ),
              ),

              // ==================================================
              // ELIMINAR
              // ==================================================
              if (isEditing) ...[
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: isWorking ? null : _delete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.error,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            color: AppColors.error,
                          ),
                    label: Text(
                      _isDeleting ? 'Eliminando...' : 'Eliminar gasto',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
