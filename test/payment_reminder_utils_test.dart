import 'package:fintrack/features/payments/domain/payment.dart';
import 'package:fintrack/features/payments/presentation/payment_reminder_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 24, 18, 30);

  Payment payment(String id, int day) {
    return Payment(
      id: id,
      name: 'Pago $id',
      amount: 100,
      dueDate: DateTime(2026, 10, day),
    );
  }

  test('identifica pagos vencidos y próximos', () {
    final summary = PaymentReminderSummary.fromPayments([
      payment('vencido', 23),
      payment('hoy', 24),
      payment('manana', 25),
      payment('tres-dias', 27),
      payment('lejano', 30),
    ], now: now);

    expect(summary.overdueCount, 1);
    expect(summary.dueTodayCount, 1);
    expect(summary.dueTomorrowCount, 1);
    expect(summary.dueSoonCount, 1);
    expect(summary.hasAlert, isTrue);
    expect(summary.priorityPayment?.id, 'vencido');
  });

  test('no genera alerta si todos los pagos están a más de tres días', () {
    final summary = PaymentReminderSummary.fromPayments([
      payment('lejano', 30),
    ], now: now);

    expect(summary.hasAlert, isFalse);
  });

  test('genera etiquetas de vencimiento en español', () {
    expect(paymentDueLabel(DateTime(2026, 10, 23), now: now), 'Venció ayer');
    expect(paymentDueLabel(DateTime(2026, 10, 24), now: now), 'Vence hoy');
    expect(paymentDueLabel(DateTime(2026, 10, 25), now: now), 'Vence mañana');
    expect(paymentDueLabel(DateTime(2026, 10, 27), now: now), 'En 3 días');
  });
}
