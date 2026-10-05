import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../../calendar/calendar_service.dart';
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
  // BUSCAR PAGO ACTUAL
  // ==================================================

  Payment? _findPayment(String id) {
    for (final payment in state) {
      if (payment.id == id) {
        return payment;
      }
    }

    return null;
  }

  // ==================================================
  // AGREGAR
  // ==================================================

  Future<void> addPayment({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    final repository = await _repository();

    // Primero creamos el evento en Google Calendar.
    final calendarEventId = await CalendarService.createEvent(
      name: name,
      amount: amount,
      dueDate: dueDate,
    );

    final payment = Payment(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      dueDate: dueDate,
      googleCalendarEventId: calendarEventId,
    );

    try {
      await repository.addPayment(payment);
    } catch (_) {
      // Si Firestore falla, intentamos no dejar
      // un evento huérfano en Google Calendar.
      try {
        await CalendarService.deleteEvent(eventId: calendarEventId);
      } catch (_) {
        // No ocultamos el error original
        // de Firestore.
      }

      rethrow;
    }
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
    final repository = await _repository();

    final previous = _findPayment(id);

    if (previous == null) {
      throw StateError('No se encontró el pago que deseas editar.');
    }

    String? calendarEventId = previous.googleCalendarEventId;

    bool createdNewCalendarEvent = false;

    // Pagos antiguos creados antes de esta
    // integración todavía no tienen eventId.
    if (calendarEventId == null || calendarEventId.isEmpty) {
      calendarEventId = await CalendarService.createEvent(
        name: name,
        amount: amount,
        dueDate: dueDate,
      );

      createdNewCalendarEvent = true;
    } else {
      await CalendarService.updateEvent(
        eventId: calendarEventId,
        name: name,
        amount: amount,
        dueDate: dueDate,
      );
    }

    final updatedPayment = previous.copyWith(
      name: name,
      amount: amount,
      dueDate: dueDate,
      googleCalendarEventId: calendarEventId,
    );

    try {
      await repository.updatePayment(updatedPayment);
    } catch (_) {
      // Intentamos devolver Calendar al estado anterior
      // si Firestore falla.

      if (createdNewCalendarEvent) {
        try {
          await CalendarService.deleteEvent(eventId: calendarEventId);
        } catch (_) {}
      } else {
        try {
          await CalendarService.updateEvent(
            eventId: calendarEventId,
            name: previous.name,
            amount: previous.amount,
            dueDate: previous.dueDate,
          );
        } catch (_) {}
      }

      rethrow;
    }
  }

  // ==================================================
  // ELIMINAR
  // ==================================================

  Future<void> deletePayment(String id) async {
    final repository = await _repository();

    final payment = _findPayment(id);

    if (payment == null) {
      throw StateError('No se encontró el pago que deseas eliminar.');
    }

    final calendarEventId = payment.googleCalendarEventId;

    // Si tiene evento asociado,
    // lo eliminamos primero de Calendar.
    if (calendarEventId != null && calendarEventId.isNotEmpty) {
      await CalendarService.deleteEvent(eventId: calendarEventId);
    }

    await repository.deletePayment(id);
  }
}

final paymentsProvider = NotifierProvider<PaymentsNotifier, List<Payment>>(
  PaymentsNotifier.new,
);

// ====================================================
// TOTAL
// ====================================================

final totalPendingPaymentsProvider = Provider<double>((ref) {
  final payments = ref.watch(paymentsProvider);

  return payments.fold<double>(0, (total, payment) => total + payment.amount);
});
