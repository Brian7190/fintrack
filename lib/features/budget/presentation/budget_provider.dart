import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/auth_provider.dart';
import '../data/repositories/firestore_budget_repository.dart';
import '../domain/monthly_budget.dart';
import '../domain/repositories/budget_repository.dart';

// ====================================================
// ESTADO
// ====================================================

class BudgetState {
  final MonthlyBudget? current;
  final List<MonthlyBudget> history;

  const BudgetState({this.current, this.history = const []});
}

// ====================================================
// REPOSITORIO POR USUARIO
// ====================================================

final budgetRepositoryProvider = Provider.family<BudgetRepository, String>((
  ref,
  userId,
) {
  return FirestoreBudgetRepository(userId: userId);
});

// ====================================================
// NOTIFIER
// ====================================================

class BudgetNotifier extends Notifier<BudgetState> {
  StreamSubscription<List<MonthlyBudget>>? _subscription;

  String? _currentUserId;

  BudgetState _cachedState = const BudgetState();

  @override
  BudgetState build() {
    final authState = ref.watch(authStateProvider);

    final user = authState.asData?.value;

    final userId = user?.uid;

    // Si cambia la cuenta, dejamos de escuchar
    // los presupuestos del usuario anterior.
    if (_currentUserId != userId) {
      _subscription?.cancel();
      _subscription = null;

      _currentUserId = userId;

      _cachedState = const BudgetState();
    }

    // Sin usuario = sin presupuesto.
    if (userId == null) {
      return _cachedState;
    }

    final repository = ref.read(budgetRepositoryProvider(userId));

    _subscription ??= repository.watchBudgets().listen(
      (budgets) {
        final now = DateTime.now();

        MonthlyBudget? current;

        for (final budget in budgets) {
          if (budget.belongsTo(now)) {
            current = budget;
            break;
          }
        }

        _cachedState = BudgetState(current: current, history: budgets);

        state = _cachedState;
      },
      onError: (_) {
        _cachedState = const BudgetState();

        state = _cachedState;
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return _cachedState;
  }

  // ==================================================
  // GUARDAR PRESUPUESTO
  // ==================================================

  Future<void> saveBudget(double amount) async {
    if (amount <= 0) {
      return;
    }

    var userId = _currentUserId;

    // Protección adicional por si el StreamProvider
    // todavía está actualizándose después del login.
    if (userId == null) {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      userId = user?.uid;
    }

    if (userId == null) {
      throw StateError('No existe un usuario autenticado.');
    }

    final now = DateTime.now();

    MonthlyBudget? existing;

    for (final budget in _cachedState.history) {
      if (budget.month == now.month && budget.year == now.year) {
        existing = budget;
        break;
      }
    }

    final MonthlyBudget budget;

    if (existing != null) {
      budget = existing.copyWith(amount: amount, updatedAt: now);
    } else {
      budget = MonthlyBudget(
        amount: amount,
        month: now.month,
        year: now.year,
        createdAt: now,
        updatedAt: now,
      );
    }

    final repository = ref.read(budgetRepositoryProvider(userId));

    await repository.saveBudget(budget);

    // No actualizamos state manualmente.
    // El listener de Firestore recibirá automáticamente
    // el documento nuevo o actualizado.
  }

  // ==================================================
  // ELIMINAR PRESUPUESTO ACTUAL
  // ==================================================

  Future<void> clearBudget() async {
    final budget = _cachedState.current;

    if (budget == null) {
      return;
    }

    var userId = _currentUserId;

    if (userId == null) {
      final user = await ref.read(authRepositoryProvider).getCurrentUser();

      userId = user?.uid;
    }

    if (userId == null) {
      throw StateError('No existe un usuario autenticado.');
    }

    final repository = ref.read(budgetRepositoryProvider(userId));

    await repository.deleteBudget(budget.periodKey);
  }
}

// ====================================================
// PROVIDER PRINCIPAL
// ====================================================

final budgetStateProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);

// ====================================================
// PRESUPUESTO ACTUAL
// ====================================================

final currentBudgetProvider = Provider<MonthlyBudget?>((ref) {
  final budgetState = ref.watch(budgetStateProvider);

  final current = budgetState.current;

  if (current == null) {
    return null;
  }

  final now = DateTime.now();

  if (!current.belongsTo(now)) {
    return null;
  }

  return current;
});

// ====================================================
// COMPATIBILIDAD CON HOME Y ESTADÍSTICAS
// ====================================================

final budgetProvider = Provider<double?>((ref) {
  return ref.watch(currentBudgetProvider)?.amount;
});

// ====================================================
// HISTORIAL
// ====================================================

final budgetHistoryProvider = Provider<List<MonthlyBudget>>((ref) {
  return ref.watch(budgetStateProvider).history;
});
