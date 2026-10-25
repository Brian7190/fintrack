import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/app_config.dart';
import '../../calendar/calendar_service.dart';
import '../../calendar/google_calendar_connect_button.dart';
import '../domain/payment.dart';
import 'payment_form_sheet.dart';
import 'payment_reminder_utils.dart';
import 'payments_provider.dart';

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  // ====================================================
  // ABRIR FORMULARIO
  // ====================================================

  void _openForm(BuildContext context, {Payment? payment}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return PaymentFormSheet(payment: payment);
      },
    );
  }

  // ====================================================
  // BUILD
  // ====================================================

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payments = ref.watch(paymentsProvider);

    final total = ref.watch(totalPendingPaymentsProvider);
    final reminder = PaymentReminderSummary.fromPayments(payments);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Próximos pagos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ==================================================
      // AGREGAR PAGO
      // ==================================================
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          _openForm(context);
        },
        child: const Icon(Icons.add),
      ),

      // ==================================================
      // CONTENIDO
      // ==================================================
      body: SafeArea(
        child: payments.isEmpty
            ? _EmptyPayments(
                onAdd: () {
                  _openForm(context);
                },
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =====================================
                    // RESUMEN
                    // =====================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Pagos pendientes',
                            style: TextStyle(color: Colors.white70),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            '${payments.length} '
                            '${payments.length == 1 ? 'pago próximo' : 'pagos próximos'}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =====================================
                    // RECORDATORIOS DE PAGOS
                    // =====================================
                    const Text(
                      'Recordatorios de pagos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'FinTrack te avisa dentro de la app cuando un pago está próximo o vencido.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (reminder.hasAlert)
                      _PaymentReminderBanner(summary: reminder)
                    else
                      const _PaymentReminderReadyCard(),

                    // Google Calendar se conserva como función opcional para
                    // una futura compilación Android. En Amazon permanece
                    // desactivado y la app no depende de él para los pagos.
                    if (AppConfig.googleCalendarEnabled && kIsWeb) ...[
                      const SizedBox(height: 18),

                      FutureBuilder<void>(
                        future: CalendarService.initialize(),
                        builder: (context, initializationSnapshot) {
                          if (initializationSnapshot.connectionState !=
                              ConnectionState.done) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (initializationSnapshot.hasError) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Google Calendar no está disponible en este momento.',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return StreamBuilder(
                            stream: CalendarService.accountChanges,
                            initialData: CalendarService.currentGoogleUser,
                            builder: (context, accountSnapshot) {
                              final googleUser = accountSnapshot.data;

                              if (googleUser != null) {
                                return Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9F6EF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Google Calendar conectado: ${googleUser.email}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Column(
                                  children: [
                                    Text(
                                      'Google Calendar (opcional)',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    GoogleCalendarConnectButton(),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 18),

                    // =====================================
                    // LISTADO DE PAGOS
                    // =====================================
                    for (final payment in payments)
                      _PaymentCard(
                        payment: payment,
                        onTap: () {
                          _openForm(context, payment: payment);
                        },
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PaymentReminderBanner extends StatelessWidget {
  final PaymentReminderSummary summary;

  const _PaymentReminderBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    final payment = summary.priorityPayment;
    final days = summary.priorityDays;

    final bool overdue = summary.hasOverdue;
    final Color background = overdue
        ? const Color(0xFFFFEEEE)
        : const Color(0xFFFFF8E8);
    final Color border = overdue
        ? const Color(0xFFF2B8B5)
        : const Color(0xFFF0D9A6);
    final Color foreground = overdue
        ? AppColors.error
        : const Color(0xFF9A6700);

    String title;
    String message;

    if (summary.overdueCount > 0) {
      title = summary.overdueCount == 1
          ? 'Tienes un pago vencido'
          : 'Tienes ${summary.overdueCount} pagos vencidos';
      message = payment == null
          ? 'Revisa tus pagos pendientes.'
          : '${payment.name} • ${paymentDueLabel(payment.dueDate)} • \$${payment.amount.toStringAsFixed(2)}';
    } else if (summary.dueTodayCount > 0) {
      title = summary.dueTodayCount == 1
          ? 'Tienes un pago que vence hoy'
          : 'Tienes ${summary.dueTodayCount} pagos que vencen hoy';
      message = payment == null
          ? 'Revisa tus pagos pendientes.'
          : '${payment.name} • \$${payment.amount.toStringAsFixed(2)}';
    } else if (summary.dueTomorrowCount > 0) {
      title = summary.dueTomorrowCount == 1
          ? 'Tienes un pago que vence mañana'
          : 'Tienes ${summary.dueTomorrowCount} pagos que vencen mañana';
      message = payment == null
          ? 'Revisa tus pagos pendientes.'
          : '${payment.name} • \$${payment.amount.toStringAsFixed(2)}';
    } else {
      title = 'Tienes un pago próximo';
      message = payment == null || days == null
          ? 'Revisa tus pagos pendientes.'
          : '${payment.name} • En $days días • \$${payment.amount.toStringAsFixed(2)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            overdue
                ? Icons.warning_amber_rounded
                : Icons.notifications_active_outlined,
            color: foreground,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
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

class _PaymentReminderReadyCard extends StatelessWidget {
  const _PaymentReminderReadyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.notifications_none_outlined, color: AppColors.primary),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'No tienes pagos que venzan en los próximos 3 días.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ====================================================
// SIN PAGOS
// ====================================================

class _EmptyPayments extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyPayments({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFE9F6EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No tienes pagos próximos',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              'Agrega servicios, recibos o cualquier pago que no quieras olvidar.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),

            const SizedBox(height: 10),

            const Text(
              'FinTrack te avisará dentro de la app cuando se acerque la fecha de un pago.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),

            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Agregar pago'),
            ),
          ],
        ),
      ),
    );
  }
}

// ====================================================
// TARJETA DE PAGO
// ====================================================

class _PaymentCard extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  const _PaymentCard({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ==================================================
    // FECHA
    // ==================================================

    final date = DateFormat('dd/MM/yyyy').format(payment.dueDate);

    final days = paymentDaysUntil(payment.dueDate);
    final status = paymentDueLabel(payment.dueDate);

    // ==================================================
    // TARJETA
    // ==================================================

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // =======================================
                // ICONO
                // =======================================
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F6EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_outlined,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 14),

                // =======================================
                // INFORMACIÓN
                // =======================================
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '$date • $status',
                        style: TextStyle(
                          color: days <= 0
                              ? AppColors.error
                              : days <= 3
                              ? const Color(0xFF9A6700)
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: days <= 3
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),

                      // =================================
                      // GOOGLE CALENDAR
                      // =================================
                      if (AppConfig.googleCalendarEnabled &&
                          payment.isSyncedWithGoogleCalendar) ...[
                        const SizedBox(height: 7),

                        const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: AppColors.primary,
                            ),

                            SizedBox(width: 4),

                            Text(
                              'Google Calendar',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // =======================================
                // MONTO
                // =======================================
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${payment.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 5),

                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                      size: 21,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
