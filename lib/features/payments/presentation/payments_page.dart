import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../calendar/calendar_service.dart';
import '../../calendar/google_calendar_connect_button.dart';
import '../domain/payment.dart';
import 'payment_form_sheet.dart';
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
                    // CALENDARIO DE PAGOS
                    // =====================================
                    const Text(
                      'Calendario de pagos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      'Tus pagos se sincronizan con Google Calendar.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),

                    // =====================================
                    // CONEXIÓN GOOGLE CALENDAR WEB
                    // =====================================
                    if (kIsWeb) ...[
                      const SizedBox(height: 14),

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
                                      'No fue posible inicializar Google Calendar.',
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

                              // =================================
                              // CUENTA CONECTADA
                              // =================================

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
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Google Calendar conectado',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),

                                            const SizedBox(height: 2),

                                            Text(
                                              googleUser.email,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // =================================
                              // CONECTAR CUENTA
                              // =================================

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
                                    Icon(
                                      Icons.calendar_month_outlined,
                                      color: AppColors.primary,
                                      size: 30,
                                    ),

                                    SizedBox(height: 8),

                                    Text(
                                      'Conecta Google Calendar',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    SizedBox(height: 4),

                                    Text(
                                      'Conecta tu cuenta de Google para crear, editar y eliminar automáticamente los eventos de tus pagos.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),

                                    SizedBox(height: 14),

                                    GoogleCalendarConnectButton(),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 14),

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
              'Los pagos pueden sincronizarse con Google Calendar.',
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

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final paymentDate = DateTime(
      payment.dueDate.year,
      payment.dueDate.month,
      payment.dueDate.day,
    );

    final days = paymentDate.difference(today).inDays;

    // ==================================================
    // ESTADO
    // ==================================================

    String status;

    if (days == 0) {
      status = 'Vence hoy';
    } else if (days == 1) {
      status = 'Vence mañana';
    } else if (days > 1) {
      status = 'En $days días';
    } else {
      status = 'Vencido';
    }

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
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),

                      // =================================
                      // GOOGLE CALENDAR
                      // =================================
                      if (payment.isSyncedWithGoogleCalendar) ...[
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
