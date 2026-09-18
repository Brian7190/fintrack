class Payment {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;

  const Payment({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
  });

  Payment copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
  }) {
    return Payment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}
