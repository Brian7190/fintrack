import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/memory_expense_repository.dart';
import '../domain/expense.dart';
import '../domain/expense_category.dart';
import '../domain/repositories/expense_repository.dart';

// ====================================================
// REPOSITORIO
// ====================================================

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return MemoryExpenseRepository();
});

// ====================================================
// CRUD DE GASTOS
// ====================================================

class ExpensesNotifier extends Notifier<List<Expense>> {
  ExpenseRepository get _repository {
    return ref.read(expenseRepositoryProvider);
  }

  @override
  List<Expense> build() {
    return _repository.getExpenses();
  }

  void addExpense({
    required String name,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
  }) {
    final expense = Expense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: name,
      amount: amount,
      date: date,
      category: category,
    );

    _repository.addExpense(expense);

    state = _repository.getExpenses();
  }

  void updateExpense({
    required String id,
    required String name,
    required double amount,
    required ExpenseCategory category,
    required DateTime date,
  }) {
    final currentExpense = state.firstWhere((expense) => expense.id == id);

    final updatedExpense = currentExpense.copyWith(
      name: name,
      amount: amount,
      category: category,
      date: date,
    );

    _repository.updateExpense(updatedExpense);

    state = _repository.getExpenses();
  }

  void deleteExpense(String id) {
    _repository.deleteExpense(id);

    state = _repository.getExpenses();
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, List<Expense>>(
  ExpensesNotifier.new,
);

// ====================================================
// FILTROS Y ORDENAMIENTO
// ====================================================

enum ExpenseSortOrder { newest, highestAmount, lowestAmount }

extension ExpenseSortOrderExtension on ExpenseSortOrder {
  String get label {
    switch (this) {
      case ExpenseSortOrder.newest:
        return 'Más recientes';

      case ExpenseSortOrder.highestAmount:
        return 'Mayor monto';

      case ExpenseSortOrder.lowestAmount:
        return 'Menor monto';
    }
  }
}

class ExpenseFilterState {
  final DateTime selectedMonth;
  final String searchQuery;
  final ExpenseCategory? category;
  final ExpenseSortOrder sortOrder;

  const ExpenseFilterState({
    required this.selectedMonth,
    this.searchQuery = '',
    this.category,
    this.sortOrder = ExpenseSortOrder.newest,
  });

  ExpenseFilterState copyWith({
    DateTime? selectedMonth,
    String? searchQuery,
    ExpenseCategory? category,
    ExpenseSortOrder? sortOrder,
    bool clearCategory = false,
  }) {
    return ExpenseFilterState(
      selectedMonth: selectedMonth ?? this.selectedMonth,
      searchQuery: searchQuery ?? this.searchQuery,
      category: clearCategory ? null : category ?? this.category,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}

class ExpenseFilterNotifier extends Notifier<ExpenseFilterState> {
  @override
  ExpenseFilterState build() {
    final now = DateTime.now();

    return ExpenseFilterState(selectedMonth: DateTime(now.year, now.month));
  }

  void setSearch(String value) {
    state = state.copyWith(searchQuery: value);
  }

  void setCategory(ExpenseCategory? category) {
    state = state.copyWith(category: category, clearCategory: category == null);
  }

  void setSortOrder(ExpenseSortOrder order) {
    state = state.copyWith(sortOrder: order);
  }

  void previousMonth() {
    final month = state.selectedMonth;

    state = state.copyWith(
      selectedMonth: DateTime(month.year, month.month - 1),
    );
  }

  void nextMonth() {
    final month = state.selectedMonth;

    final next = DateTime(month.year, month.month + 1);

    final now = DateTime.now();

    final currentMonth = DateTime(now.year, now.month);

    // No permitimos seleccionar meses futuros.
    if (next.isAfter(currentMonth)) {
      return;
    }

    state = state.copyWith(selectedMonth: next);
  }

  void goToCurrentMonth() {
    final now = DateTime.now();

    state = state.copyWith(selectedMonth: DateTime(now.year, now.month));
  }
}

final expenseFilterProvider =
    NotifierProvider<ExpenseFilterNotifier, ExpenseFilterState>(
      ExpenseFilterNotifier.new,
    );

// ====================================================
// GASTOS DEL MES SELECCIONADO
// ====================================================

final selectedMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);

  final selectedMonth = ref.watch(expenseFilterProvider).selectedMonth;

  return expenses.where((expense) {
    return expense.date.year == selectedMonth.year &&
        expense.date.month == selectedMonth.month;
  }).toList();
});

final selectedMonthExpensesTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(selectedMonthExpensesProvider);

  return expenses.fold<double>(0, (total, expense) => total + expense.amount);
});

final selectedMonthExpensesByCategoryProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
      final expenses = ref.watch(selectedMonthExpensesProvider);

      final totals = <ExpenseCategory, double>{};

      for (final expense in expenses) {
        totals.update(
          expense.category,
          (current) => current + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      return totals;
    });

// ====================================================
// RESULTADOS VISIBLES CON BUSCADOR + FILTRO + ORDEN
// ====================================================

final filteredExpensesProvider = Provider<List<Expense>>((ref) {
  final filter = ref.watch(expenseFilterProvider);

  final monthExpenses = ref.watch(selectedMonthExpensesProvider);

  var expenses = List<Expense>.from(monthExpenses);

  final search = filter.searchQuery.trim().toLowerCase();

  if (search.isNotEmpty) {
    expenses = expenses.where((expense) {
      return expense.name.toLowerCase().contains(search);
    }).toList();
  }

  if (filter.category != null) {
    expenses = expenses.where((expense) {
      return expense.category == filter.category;
    }).toList();
  }

  switch (filter.sortOrder) {
    case ExpenseSortOrder.newest:
      expenses.sort((a, b) => b.date.compareTo(a.date));
      break;

    case ExpenseSortOrder.highestAmount:
      expenses.sort((a, b) => b.amount.compareTo(a.amount));
      break;

    case ExpenseSortOrder.lowestAmount:
      expenses.sort((a, b) => a.amount.compareTo(b.amount));
      break;
  }

  return expenses;
});

// ====================================================
// PROVIDERS DEL MES ACTUAL
// Siguen siendo usados por Home y Estadísticas.
// ====================================================

final currentMonthExpensesProvider = Provider<List<Expense>>((ref) {
  final expenses = ref.watch(expensesProvider);

  final now = DateTime.now();

  return expenses.where((expense) {
    return expense.date.year == now.year && expense.date.month == now.month;
  }).toList();
});

final currentMonthExpensesTotalProvider = Provider<double>((ref) {
  final expenses = ref.watch(currentMonthExpensesProvider);

  return expenses.fold<double>(0, (total, expense) => total + expense.amount);
});

final currentMonthExpensesByCategoryProvider =
    Provider<Map<ExpenseCategory, double>>((ref) {
      final expenses = ref.watch(currentMonthExpensesProvider);

      final totals = <ExpenseCategory, double>{};

      for (final expense in expenses) {
        totals.update(
          expense.category,
          (current) => current + expense.amount,
          ifAbsent: () => expense.amount,
        );
      }

      return totals;
    });

// Se mantiene por compatibilidad.
final totalExpensesProvider = Provider<double>((ref) {
  final expenses = ref.watch(expensesProvider);

  return expenses.fold<double>(0, (total, expense) => total + expense.amount);
});

final expensesByCategoryProvider = Provider<Map<ExpenseCategory, double>>((
  ref,
) {
  final expenses = ref.watch(expensesProvider);

  final totals = <ExpenseCategory, double>{};

  for (final expense in expenses) {
    totals.update(
      expense.category,
      (current) => current + expense.amount,
      ifAbsent: () => expense.amount,
    );
  }

  return totals;
});
