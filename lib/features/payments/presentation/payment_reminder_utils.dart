import '../domain/payment.dart';

class PaymentReminderSummary {
  final int overdueCount;
  final int dueTodayCount;
  final int dueTomorrowCount;
  final int dueSoonCount;
  final Payment? priorityPayment;
  final int? priorityDays;

  const PaymentReminderSummary({
    required this.overdueCount,
    required this.dueTodayCount,
    required this.dueTomorrowCount,
    required this.dueSoonCount,
    required this.priorityPayment,
    required this.priorityDays,
  });

  bool get hasAlert =>
      overdueCount > 0 ||
      dueTodayCount > 0 ||
      dueTomorrowCount > 0 ||
      dueSoonCount > 0;

  bool get hasOverdue => overdueCount > 0;

  static PaymentReminderSummary fromPayments(
    List<Payment> payments, {
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final today = DateTime(reference.year, reference.month, reference.day);

    var overdue = 0;
    var todayCount = 0;
    var tomorrow = 0;
    var soon = 0;

    Payment? priority;
    int? priorityDays;

    for (final payment in payments) {
      final due = DateTime(
        payment.dueDate.year,
        payment.dueDate.month,
        payment.dueDate.day,
      );
      final days = due.difference(today).inDays;

      if (days < 0) {
        overdue++;
      } else if (days == 0) {
        todayCount++;
      } else if (days == 1) {
        tomorrow++;
      } else if (days <= 3) {
        soon++;
      }

      if (days <= 3) {
        if (priority == null || _isHigherPriority(days, priorityDays!)) {
          priority = payment;
          priorityDays = days;
        }
      }
    }

    return PaymentReminderSummary(
      overdueCount: overdue,
      dueTodayCount: todayCount,
      dueTomorrowCount: tomorrow,
      dueSoonCount: soon,
      priorityPayment: priority,
      priorityDays: priorityDays,
    );
  }

  static bool _isHigherPriority(int candidateDays, int currentDays) {
    // Un pago vencido tiene prioridad sobre uno futuro. Entre vencidos,
    // mostramos primero el más cercano a hoy (-1 antes que -10).
    if (candidateDays < 0 && currentDays >= 0) {
      return true;
    }
    if (candidateDays >= 0 && currentDays < 0) {
      return false;
    }
    if (candidateDays < 0 && currentDays < 0) {
      return candidateDays > currentDays;
    }

    return candidateDays < currentDays;
  }
}

int paymentDaysUntil(DateTime dueDate, {DateTime? now}) {
  final reference = now ?? DateTime.now();
  final today = DateTime(reference.year, reference.month, reference.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  return due.difference(today).inDays;
}

String paymentDueLabel(DateTime dueDate, {DateTime? now}) {
  final days = paymentDaysUntil(dueDate, now: now);

  if (days < 0) {
    return days == -1 ? 'Venció ayer' : 'Vencido hace ${days.abs()} días';
  }
  if (days == 0) {
    return 'Vence hoy';
  }
  if (days == 1) {
    return 'Vence mañana';
  }
  return 'En $days días';
}
