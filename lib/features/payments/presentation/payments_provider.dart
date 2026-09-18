import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/memory_payment_repository.dart';
import '../domain/payment.dart';
import '../domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return MemoryPaymentRepository();
});

class PaymentsNotifier extends Notifier<List<Payment>> {
  PaymentRepository get _repository {
    return ref.read(paymentRepositoryProvider);
  }

  @override
  List<Payment> build() {
    return _repository.getPayments();
  }

  void addPayment({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) {
    final payment = Payment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      dueDate: dueDate,
    );

    _repository.addPayment(payment);

    state = _repository.getPayments();
  }

  void updatePayment({
    required String id,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) {
    final currentPayment = state.firstWhere((payment) => payment.id == id);

    final updatedPayment = currentPayment.copyWith(
      name: name,
      amount: amount,
      dueDate: dueDate,
    );

    _repository.updatePayment(updatedPayment);

    state = _repository.getPayments();
  }

  void deletePayment(String id) {
    _repository.deletePayment(id);

    state = _repository.getPayments();
  }
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

final totalPendingPaymentsProvider = Provider<double>((ref) {
  final payments = ref.watch(paymentsProvider);

  return payments.fold<double>(0, (total, payment) => total + payment.amount);
});
