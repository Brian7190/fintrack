class AdminUserBudget {
  final double amount;
  final int month;
  final int year;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserBudget({
    required this.amount,
    required this.month,
    required this.year,
    this.createdAt,
    this.updatedAt,
  });

  String get periodKey {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  String get periodLabel {
    return _formatPeriod(month: month, year: year);
  }

  static String currentPeriodKey() {
    final now = DateTime.now();

    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  static String _formatPeriod({required int month, required int year}) {
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
}
