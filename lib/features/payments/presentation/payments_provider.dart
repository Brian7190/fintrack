import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/repositories/firestore_payment_repository.dart';
import '../domain/payment.dart';
import '../domain/repositories/payment_repository.dart';

// ====================================================
// REPOSITORIO POR USUARIO
// ====================================================

final paymentRepositoryProvider = Provider.family<PaymentRepository, String>((
  ref,
  userId,
) {
  return FirestorePaymentRepository(userId: userId);
});

// ====================================================
// NOTIFIER
// ====================================================

class PaymentsNotifier extends Notifier<List<Payment>> {
  StreamSubscription<List<Payment>>? _subscription;

  String? _currentUserId;

  List<Payment> _cachedPayments = const <Payment>[];

  @override
  List<Payment> build() {
    final authState = ref.watch(authStateProvider);

    final userId = authState.asData?.value?.uid;

    // Si cambia la cuenta, dejamos de escuchar
    // los pagos de la cuenta anterior.
    if (_currentUserId != userId) {
      _subscription?.cancel();

      _subscription = null;
      _currentUserId = userId;
      _cachedPayments = const <Payment>[];
    }

    if (userId == null) {
      return _cachedPayments;
    }

    final repository = ref.read(paymentRepositoryProvider(userId));

    _subscription ??= repository.watchPayments().listen(
      (payments) {
        _cachedPayments = payments;
        state = payments;
      },
      onError: (_) {
        _cachedPayments = const <Payment>[];

        state = const <Payment>[];
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return _cachedPayments;
  }

  Future<PaymentRepository> _repository() async {
    var userId = _currentUserId;

    if (userId == null) {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      userId = user?.uid;
    }

    if (userId == null) {
      throw StateError('No existe un usuario autenticado.');
    }

    return ref.read(paymentRepositoryProvider(userId));
  }

  // ==================================================
  // AGREGAR
  // ==================================================

  Future<void> addPayment({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    final payment = Payment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      dueDate: dueDate,
    );

    final repository = await _repository();

    await repository.addPayment(payment);
  }

  // ==================================================
  // ACTUALIZAR
  // ==================================================

  Future<void> updatePayment({
    required String id,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    final payment = Payment(
      id: id,
      name: name,
      amount: amount,
      dueDate: dueDate,
    );

    final repository = await _repository();

    await repository.updatePayment(payment);
  }

  // ==================================================
  // ELIMINAR
  // ==================================================

  Future<void> deletePayment(String id) async {
    final repository = await _repository();

    await repository.deletePayment(id);
  }
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

// ====================================================
// TOTAL DE PAGOS
// ====================================================

final totalPendingPaymentsProvider = Provider<double>((ref) {
  final payments = ref.watch(paymentsProvider);

  return payments.fold<double>(0, (total, payment) => total + payment.amount);
});
