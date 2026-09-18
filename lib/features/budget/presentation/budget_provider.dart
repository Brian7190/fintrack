import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/monthly_budget.dart';

class BudgetState {
  final MonthlyBudget? current;
  final List<MonthlyBudget> history;

  const BudgetState({this.current, this.history = const []});

  BudgetState copyWith({MonthlyBudget? current, List<MonthlyBudget>? history}) {
    return BudgetState(
      current: current ?? this.current,
      history: history ?? this.history,
    );
  }
}

class BudgetNotifier extends Notifier<BudgetState> {
  @override
  BudgetState build() {
    return const BudgetState();
  }

  void saveBudget(double amount) {
    if (amount <= 0) {
      return;
    }

    final now = DateTime.now();

    final existingIndex = state.history.indexWhere((budget) {
      return budget.month == now.month && budget.year == now.year;
    });

    late final MonthlyBudget budget;

    final updatedHistory = List<MonthlyBudget>.from(state.history);

    if (existingIndex >= 0) {
      final existing = updatedHistory[existingIndex];

      budget = existing.copyWith(amount: amount, updatedAt: now);

      updatedHistory[existingIndex] = budget;
    } else {
      budget = MonthlyBudget(
        amount: amount,
        month: now.month,
        year: now.year,
        createdAt: now,
        updatedAt: now,
      );

      updatedHistory.add(budget);
    }

    updatedHistory.sort((a, b) {
      final dateA = DateTime(a.year, a.month);
      final dateB = DateTime(b.year, b.month);

      return dateB.compareTo(dateA);
    });

    state = BudgetState(current: budget, history: updatedHistory);
  }

  void clearBudget() {
    state = BudgetState(history: state.history);
  }
}

final budgetStateProvider = NotifierProvider<BudgetNotifier, BudgetState>(
  BudgetNotifier.new,
);

final currentBudgetProvider = Provider<MonthlyBudget?>((ref) {
  final state = ref.watch(budgetStateProvider);
  final current = state.current;

  if (current == null) {
    return null;
  }

  final now = DateTime.now();

  if (!current.belongsTo(now)) {
    return null;
  }

  return current;
});

// Mantiene compatibilidad con Home y Estadísticas.
// Sigue entregando double?, como antes.
final budgetProvider = Provider<double?>((ref) {
  return ref.watch(currentBudgetProvider)?.amount;
});

// Ya queda preparado para Firebase posteriormente.
final budgetHistoryProvider = Provider<List<MonthlyBudget>>((ref) {
  return ref.watch(budgetStateProvider).history;
});
