import 'package:flutter_riverpod/flutter_riverpod.dart';

class BudgetNotifier extends Notifier<double?> {
  @override
  double? build() {
    // Un usuario nuevo todavía no tiene presupuesto.
    return null;
  }

  void updateBudget(double newBudget) {
    if (newBudget <= 0) {
      return;
    }

    state = newBudget;
  }

  void clearBudget() {
    state = null;
  }
}

final budgetProvider = NotifierProvider<BudgetNotifier, double?>(
  BudgetNotifier.new,
);
