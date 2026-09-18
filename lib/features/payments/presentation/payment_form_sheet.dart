import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../domain/payment.dart';
import 'payments_provider.dart';

class PaymentFormSheet extends ConsumerStatefulWidget {
  final Payment? payment;

  const PaymentFormSheet({super.key, this.payment});

  @override
  ConsumerState<PaymentFormSheet> createState() => _PaymentFormSheetState();
}

class _PaymentFormSheetState extends ConsumerState<PaymentFormSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _amountController;

  DateTime? _selectedDate;

  bool get isEditing => widget.payment != null;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.payment?.name ?? '');

    _amountController = TextEditingController(
      text: widget.payment == null
          ? ''
          : widget.payment!.amount.toStringAsFixed(2),
    );

    _selectedDate = widget.payment?.dueDate;
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
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
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

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de pago')),
      );

      return;
    }

    final name = _nameController.text.trim();

    final amount = double.parse(_amountController.text.replaceAll(',', '.'));

    if (isEditing) {
      ref
          .read(paymentsProvider.notifier)
          .updatePayment(
            id: widget.payment!.id,
            name: name,
            amount: amount,
            dueDate: _selectedDate!,
          );
    } else {
      ref
          .read(paymentsProvider.notifier)
          .addPayment(name: name, amount: amount, dueDate: _selectedDate!);
    }

    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final payment = widget.payment;

    if (payment == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pago'),
          content: Text('¿Deseas eliminar "${payment.name}"?'),
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

    ref.read(paymentsProvider.notifier).deletePayment(payment.id);

    Navigator.of(context).pop();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el nombre del pago';
    }

    return null;
  }

  String? _validateAmount(String? value) {
    final text = value?.replaceAll(',', '.') ?? '';
    final amount = double.tryParse(text);

    if (text.isEmpty) {
      return 'Ingresa el monto';
    }

    if (amount == null || amount <= 0) {
      return 'Ingresa un monto válido';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _selectedDate == null
        ? 'Seleccionar fecha'
        : DateFormat('dd/MM/yyyy').format(_selectedDate!);

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
                isEditing ? 'Editar próximo pago' : 'Nuevo próximo pago',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateName,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Netflix',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
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
                validator: _validateAmount,
                decoration: const InputDecoration(
                  labelText: 'Monto',
                  hintText: 'Ej. 179.00',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de pago',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(formattedDate),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(isEditing ? 'Guardar cambios' : 'Agregar pago'),
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
                      'Eliminar pago',
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
