import '../payment.dart';

abstract class PaymentRepository {
  Stream<List<Payment>> watchPayments();

  Future<void> addPayment(Payment payment);

  Future<void> updatePayment(Payment payment);

  Future<void> deletePayment(String id);
}
