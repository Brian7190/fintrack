import '../../domain/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class MemoryPaymentRepository implements PaymentRepository {
  final List<Payment> _payments = [];

  @override
  List<Payment> getPayments() {
    final payments = List<Payment>.from(_payments);

    payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return List.unmodifiable(payments);
  }

  @override
  void addPayment(Payment payment) {
    _payments.add(payment);
  }

  @override
  void updatePayment(Payment payment) {
    final index = _payments.indexWhere((item) => item.id == payment.id);

    if (index == -1) {
      return;
    }

    _payments[index] = payment;
  }

  @override
  void deletePayment(String id) {
    _payments.removeWhere((payment) => payment.id == id);
  }
}
