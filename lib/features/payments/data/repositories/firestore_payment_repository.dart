import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/payment.dart';
import '../../domain/repositories/payment_repository.dart';

class FirestorePaymentRepository implements PaymentRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FirestorePaymentRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _paymentsCollection {
    return _firestore.collection('users').doc(userId).collection('payments');
  }

  @override
  Stream<List<Payment>> watchPayments() {
    return _paymentsCollection.snapshots().map((snapshot) {
      final payments = snapshot.docs.map(_fromFirestore).toList();

      payments.sort((a, b) => a.dueDate.compareTo(b.dueDate));

      return payments;
    });
  }

  @override
  Future<void> addPayment(Payment payment) async {
    await _paymentsCollection.doc(payment.id).set({
      'name': payment.name,
      'amount': payment.amount,
      'dueDate': Timestamp.fromDate(payment.dueDate),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updatePayment(Payment payment) async {
    await _paymentsCollection.doc(payment.id).update({
      'name': payment.name,
      'amount': payment.amount,
      'dueDate': Timestamp.fromDate(payment.dueDate),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deletePayment(String id) async {
    await _paymentsCollection.doc(id).delete();
  }

  Payment _fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};

    final rawDueDate = data['dueDate'];

    final DateTime dueDate;

    if (rawDueDate is Timestamp) {
      dueDate = rawDueDate.toDate();
    } else {
      dueDate = DateTime.now();
    }

    return Payment(
      id: document.id,
      name: data['name'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      dueDate: dueDate,
    );
  }
}
