import 'payment.dart';

/// Compara únicamente pagos del usuario autenticado que recibe la pantalla.
class PaymentDuplicateRules {
  PaymentDuplicateRules._();

  static String normalizeName(String value) =>
      value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool hasExactDuplicate(
    Iterable<Payment> payments, {
    required String name,
    required double amount,
    required DateTime dueDate,
    String? excludeId,
  }) {
    final normalized = normalizeName(name);
    return payments.any(
      (payment) =>
          payment.id != excludeId &&
          normalizeName(payment.name) == normalized &&
          (payment.amount * 100).round() == (amount * 100).round() &&
          sameDay(payment.dueDate, dueDate),
    );
  }

  static bool hasSameNameInMonth(
    Iterable<Payment> payments, {
    required String name,
    required DateTime dueDate,
    String? excludeId,
  }) {
    final normalized = normalizeName(name);
    return payments.any(
      (payment) =>
          payment.id != excludeId &&
          normalizeName(payment.name) == normalized &&
          payment.dueDate.year == dueDate.year &&
          payment.dueDate.month == dueDate.month,
    );
  }
}
