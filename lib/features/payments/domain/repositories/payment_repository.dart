import '../payment.dart';

abstract class PaymentRepository {
  List<Payment> getPayments();

  void addPayment(Payment payment);

  void updatePayment(Payment payment);

  void deletePayment(String id);
}
