class Payment {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;

  final String? googleCalendarEventId;

  const Payment({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.googleCalendarEventId,
  });

  bool get isSyncedWithGoogleCalendar {
    return googleCalendarEventId != null && googleCalendarEventId!.isNotEmpty;
  }

  Payment copyWith({
    String? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    String? googleCalendarEventId,
    bool clearGoogleCalendarEventId = false,
  }) {
    return Payment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      googleCalendarEventId: clearGoogleCalendarEventId
          ? null
          : googleCalendarEventId ?? this.googleCalendarEventId,
    );
  }
}
