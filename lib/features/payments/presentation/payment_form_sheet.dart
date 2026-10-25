import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_config.dart';
import '../../../core/input_validators.dart';
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
      helpText: 'Selecciona la fecha de pago',
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
    final amount = InputValidators.parseAmount(_amountController.text)!;

    // Antes de crear un pago nuevo, avisamos si ya existe otro pago con
    // el mismo nombre dentro del mismo mes. Se permite continuar porque
    // puede tratarse de un pago legítimo repetido.
    if (!isEditing) {
      final normalizedName = name
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      final hasSameNameThisMonth = ref.read(paymentsProvider).any((payment) {
        final existingName = payment.name
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return existingName == normalizedName &&
            payment.dueDate.year == _selectedDate!.year &&
            payment.dueDate.month == _selectedDate!.month;
      });

      if (hasSameNameThisMonth) {
        final monthLabel = DateFormat(
          'MMMM yyyy',
          'es_MX',
        ).format(_selectedDate!);

        final addAnyway = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Pago con nombre repetido'),
              content: Text(
                'Ya existe un pago llamado "$name" registrado en $monthLabel. '
                '¿Deseas agregarlo de todas formas?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Agregar de todas formas'),
                ),
              ],
            );
          },
        );

        if (!mounted || addAnyway != true) {
          return;
        }
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final PaymentOperationResult result;

      if (isEditing) {
        result = await ref
            .read(paymentsProvider.notifier)
            .updatePayment(
              id: widget.payment!.id,
              name: name,
              amount: amount,
              dueDate: _selectedDate!,
            );
      } else {
        result = await ref
            .read(paymentsProvider.notifier)
            .addPayment(name: name, amount: amount, dueDate: _selectedDate!);
      }

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      final String message;

      if (result.failed) {
        message = isEditing
            ? 'Pago actualizado en FinTrack, pero no se pudo sincronizar con Google Calendar.'
            : 'Pago guardado en FinTrack, pero no se pudo sincronizar con Google Calendar.';
      } else if (result.synced) {
        message = isEditing
            ? 'Pago actualizado y sincronizado correctamente'
            : 'Pago agregado y sincronizado correctamente';
      } else {
        message = isEditing
            ? 'Pago actualizado correctamente'
            : 'Pago agregado correctamente';
      }

      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError(
        isEditing
            ? 'No fue posible actualizar el pago en FinTrack.'
            : 'No fue posible guardar el pago en FinTrack.',
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
            AppConfig.googleCalendarEnabled &&
                    payment.isSyncedWithGoogleCalendar
                ? '¿Deseas eliminar "${payment.name}"?\n\nTambién se intentará eliminar su evento de Google Calendar.'
                : '¿Deseas eliminar "${payment.name}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
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
      final result = await ref
          .read(paymentsProvider.notifier)
          .deletePayment(payment.id);

      if (!mounted) {
        return;
      }

      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.failed
                ? 'Pago eliminado de FinTrack. No se pudo eliminar el evento de Google Calendar.'
                : 'Pago eliminado correctamente',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('No fue posible eliminar el pago de FinTrack.');
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
    return InputValidators.moneyAmount(value);
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
                AppConfig.googleCalendarEnabled
                    ? (isEditing
                          ? 'El pago se guardará en FinTrack y se intentará actualizar en Google Calendar.'
                          : 'El pago se guardará en FinTrack y se intentará sincronizar con Google Calendar.')
                    : 'El pago se guardará en FinTrack.',
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
                  LengthLimitingTextInputFormatter(11),
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
              if (AppConfig.googleCalendarEnabled)
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
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF0D9A6)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.notifications_active_outlined,
                        color: Color(0xFF9A6700),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recordatorio de FinTrack',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'FinTrack te avisará dentro de la app cuando se acerque la fecha de este pago.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
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
