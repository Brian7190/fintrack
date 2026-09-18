enum ExpenseCategory {
  food,
  transport,
  services,
  entertainment,
  health,
  education,
  other,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Alimentación';
      case ExpenseCategory.transport:
        return 'Transporte';
      case ExpenseCategory.services:
        return 'Servicios';
      case ExpenseCategory.entertainment:
        return 'Entretenimiento';
      case ExpenseCategory.health:
        return 'Salud';
      case ExpenseCategory.education:
        return 'Educación';
      case ExpenseCategory.other:
        return 'Otros';
    }
  }
}
