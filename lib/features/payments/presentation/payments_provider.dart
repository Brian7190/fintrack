import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_config.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../calendar/calendar_service.dart';
import '../data/repositories/firestore_payment_repository.dart';
import '../domain/payment.dart';
import '../domain/repositories/payment_repository.dart';

final paymentRepositoryProvider = Provider.family<PaymentRepository, String>((
  ref,
  userId,
) {
  return FirestorePaymentRepository(userId: userId);
});

enum CalendarSyncResult { synced, skipped, failed }

class PaymentOperationResult {
  final CalendarSyncResult calendar;

  const PaymentOperationResult(this.calendar);

  bool get synced => calendar == CalendarSyncResult.synced;
  bool get failed => calendar == CalendarSyncResult.failed;
}

class PaymentsNotifier extends Notifier<List<Payment>> {
  StreamSubscription<List<Payment>>? _subscription;
  String? _currentUserId;
  List<Payment> _cachedPayments = const <Payment>[];

  @override
  List<Payment> build() {
    final authState = ref.watch(authStateProvider);
    final userId = authState.asData?.value?.uid;

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

  Payment? _findPayment(String id) {
    for (final payment in state) {
      if (payment.id == id) {
        return payment;
      }
    }

    return null;
  }

  Future<PaymentOperationResult> addPayment({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    final repository = await _repository();

    final payment = Payment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      dueDate: dueDate,
    );

    // El dato principal se guarda primero en FinTrack. Calendar es opcional.
    await repository.addPayment(payment);

    if (!AppConfig.googleCalendarEnabled) {
      return const PaymentOperationResult(CalendarSyncResult.skipped);
    }

    try {
      final eventId = await CalendarService.createEvent(
        name: name,
        amount: amount,
        dueDate: dueDate,
      );

      try {
        await repository.updatePayment(
          payment.copyWith(googleCalendarEventId: eventId),
        );
      } catch (_) {
        // El pago ya está guardado. Evitamos dejar un evento huérfano.
        try {
          await CalendarService.deleteEvent(eventId: eventId);
        } catch (_) {}
        return const PaymentOperationResult(CalendarSyncResult.failed);
      }

      return const PaymentOperationResult(CalendarSyncResult.synced);
    } catch (_) {
      return const PaymentOperationResult(CalendarSyncResult.failed);
    }
  }

  Future<PaymentOperationResult> updatePayment({
    required String id,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    final repository = await _repository();
    final previous = _findPayment(id);

    if (previous == null) {
      throw StateError('No se encontró el pago que deseas editar.');
    }

    // Guardamos primero el cambio en FinTrack.
    final locallyUpdated = previous.copyWith(
      name: name,
      amount: amount,
      dueDate: dueDate,
    );
    await repository.updatePayment(locallyUpdated);

    if (!AppConfig.googleCalendarEnabled) {
      return const PaymentOperationResult(CalendarSyncResult.skipped);
    }

    final existingEventId = previous.googleCalendarEventId;

    try {
      if (existingEventId == null || existingEventId.isEmpty) {
        final newEventId = await CalendarService.createEvent(
          name: name,
          amount: amount,
          dueDate: dueDate,
        );

        try {
          await repository.updatePayment(
            locallyUpdated.copyWith(googleCalendarEventId: newEventId),
          );
        } catch (_) {
          try {
            await CalendarService.deleteEvent(eventId: newEventId);
          } catch (_) {}
          return const PaymentOperationResult(CalendarSyncResult.failed);
        }
      } else {
        await CalendarService.updateEvent(
          eventId: existingEventId,
          name: name,
          amount: amount,
          dueDate: dueDate,
        );
      }

      return const PaymentOperationResult(CalendarSyncResult.synced);
    } catch (_) {
      return const PaymentOperationResult(CalendarSyncResult.failed);
    }
  }

  Future<PaymentOperationResult> deletePayment(String id) async {
    final repository = await _repository();
    final payment = _findPayment(id);

    if (payment == null) {
      throw StateError('No se encontró el pago que deseas eliminar.');
    }

    // Eliminamos siempre de FinTrack, aunque Calendar no esté disponible.
    await repository.deletePayment(id);

    if (!AppConfig.googleCalendarEnabled) {
      return const PaymentOperationResult(CalendarSyncResult.skipped);
    }

    final eventId = payment.googleCalendarEventId;

    if (eventId == null || eventId.isEmpty) {
      return const PaymentOperationResult(CalendarSyncResult.skipped);
    }

    try {
      await CalendarService.deleteEvent(eventId: eventId);
      return const PaymentOperationResult(CalendarSyncResult.synced);
    } catch (_) {
      return const PaymentOperationResult(CalendarSyncResult.failed);
    }
  }
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

final totalPendingPaymentsProvider = Provider<double>((ref) {
  final payments = ref.watch(paymentsProvider);
  return payments.fold<double>(0, (total, payment) => total + payment.amount);
});
