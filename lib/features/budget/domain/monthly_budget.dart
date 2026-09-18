class MonthlyBudget {
  final double amount;
  final int month;
  final int year;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MonthlyBudget({
    required this.amount,
    required this.month,
    required this.year,
    required this.createdAt,
    required this.updatedAt,
  });

  String get periodKey {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  String get periodLabel {
    return formatPeriod(month: month, year: year);
  }

  bool belongsTo(DateTime date) {
    return month == date.month && year == date.year;
  }

  MonthlyBudget copyWith({
    double? amount,
    int? month,
    int? year,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudget(
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String formatPeriod({required int month, required int year}) {
    const months = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    if (month < 1 || month > 12) {
      return '$month/$year';
    }

    return '${months[month - 1]} $year';
  }

  static String currentPeriodLabel() {
    final now = DateTime.now();

    return formatPeriod(month: now.month, year: now.year);
  }
}
