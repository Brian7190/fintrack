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

  bool _isSaving = false;
  bool _isDeleting = false;

  bool get isEditing => widget.payment != null;

  bool get _isBusy => _isSaving || _isDeleting;

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

  // ====================================================
  // SELECCIONAR FECHA
  // ====================================================

  Future<void> _selectDate() async {
    if (_isBusy) {
      return;
    }

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

  // ====================================================
  // GUARDAR
  // ====================================================

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;

    if (!valid || _isBusy) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha de pago')),
      );

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
            .read(paymentsProvider.notifier)
            .updatePayment(
              id: widget.payment!.id,
              name: name,
              amount: amount,
              dueDate: _selectedDate!,
            );
      } else {
        await ref
            .read(paymentsProvider.notifier)
            .addPayment(name: name, amount: amount, dueDate: _selectedDate!);
      }

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Pago actualizado correctamente'
                : 'Pago agregado correctamente',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showError(
        isEditing
            ? 'No fue posible actualizar el pago o Google Calendar.'
            : 'No fue posible guardar el pago o sincronizarlo con Google Calendar.',
      );
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
    final payment = widget.payment;

    if (payment == null || _isBusy) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar pago'),
          content: Text(
            '¿Deseas eliminar "${payment.name}"?\n\n'
            'Si está sincronizado con Google Calendar, '
            'el evento también será eliminado.',
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
      await ref.read(paymentsProvider.notifier).deletePayment(payment.id);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago eliminado correctamente')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        'No fue posible eliminar el pago o su evento de Google Calendar.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  // ====================================================
  // VALIDACIONES
  // ====================================================

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

  // ====================================================
  // ERROR
  // ====================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ====================================================
  // BUILD
  // ====================================================

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
              // ==========================================
              // TÍTULO
              // ==========================================
              Text(
                isEditing ? 'Editar próximo pago' : 'Nuevo próximo pago',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                isEditing
                    ? 'Los cambios también se aplicarán al evento de Google Calendar.'
                    : 'El pago se sincronizará automáticamente con Google Calendar.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // NOMBRE
              // ==========================================
              TextFormField(
                controller: _nameController,
                enabled: !_isBusy,
                textCapitalization: TextCapitalization.sentences,
                validator: _validateName,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Ej. Netflix',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // MONTO
              // ==========================================
              TextFormField(
                controller: _amountController,
                enabled: !_isBusy,
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

              // ==========================================
              // FECHA
              // ==========================================
              InkWell(
                onTap: _isBusy ? null : _selectDate,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de pago',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  child: Text(formattedDate),
                ),
              ),

              const SizedBox(height: 16),

              // ==========================================
              // GOOGLE CALENDAR
              // ==========================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F6EF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      color: Color(0xFF238B57),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Google Calendar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            widget.payment?.isSyncedWithGoogleCalendar == true
                                ? 'Este pago está sincronizado.'
                                : 'Se sincronizará al guardar.',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (widget.payment?.isSyncedWithGoogleCalendar == true)
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF238B57),
                        size: 20,
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // GUARDAR
              // ==========================================
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isBusy ? null : _save,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(
                    _isSaving
                        ? isEditing
                              ? 'Actualizando...'
                              : 'Guardando...'
                        : isEditing
                        ? 'Guardar cambios'
                        : 'Agregar pago',
                  ),
                ),
              ),

              // ==========================================
              // ELIMINAR
              // ==========================================
              if (isEditing) ...[
                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: _isBusy ? null : _delete,
                    icon: _isDeleting
                        ? const SizedBox(
                            width: 17,
                            height: 17,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline, color: Colors.red),
                    label: Text(
                      _isDeleting ? 'Eliminando...' : 'Eliminar pago',
                      style: const TextStyle(color: Colors.red),
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
