import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/features/payments/domain/payment.dart';
import 'package:fintrack/features/payments/domain/payment_duplicate_rules.dart';

void main() {
  final payments = [
    Payment(
      id: '1',
      name: '  Netflix  Plan ',
      amount: 176,
      dueDate: DateTime(2026, 10, 24),
    ),
  ];

  test('bloquea duplicado exacto ignorando espacios, mayúsculas y hora', () {
    expect(
      PaymentDuplicateRules.hasExactDuplicate(
        payments,
        name: 'netflix plan',
        amount: 176.00,
        dueDate: DateTime(2026, 10, 24, 19),
      ),
      isTrue,
    );
  });

  test('permite pago distinto aunque tenga nombre repetido', () {
    expect(
      PaymentDuplicateRules.hasExactDuplicate(
        payments,
        name: 'Netflix Plan',
        amount: 200,
        dueDate: DateTime(2026, 10, 24),
      ),
      isFalse,
    );
    expect(
      PaymentDuplicateRules.hasSameNameInMonth(
        payments,
        name: 'NETFLIX  PLAN',
        dueDate: DateTime(2026, 10, 30),
      ),
      isTrue,
    );
  });

  test('mismo nombre en otro mes no requiere advertencia', () {
    expect(
      PaymentDuplicateRules.hasSameNameInMonth(
        payments,
        name: 'netflix plan',
        dueDate: DateTime(2026, 11, 24),
      ),
      isFalse,
    );
  });

  test('editar el mismo pago no cuenta como duplicado de sí mismo', () {
    expect(
      PaymentDuplicateRules.hasExactDuplicate(
        payments,
        name: 'netflix plan',
        amount: 176,
        dueDate: DateTime(2026, 10, 24),
        excludeId: '1',
      ),
      isFalse,
    );
  });

  test('bloquea coincidencia exacta aunque haya otro nombre diferente', () {
    expect(
      PaymentDuplicateRules.hasExactDuplicate(
        payments,
        name: 'spotify',
        amount: 176,
        dueDate: DateTime(2026, 10, 24),
      ),
      isFalse,
    );
  });
}
