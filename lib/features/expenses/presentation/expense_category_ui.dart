import 'package:flutter/material.dart';

import '../domain/expense_category.dart';

IconData expenseCategoryIcon(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return Icons.restaurant_outlined;

    case ExpenseCategory.transport:
      return Icons.directions_bus_outlined;

    case ExpenseCategory.services:
      return Icons.home_repair_service_outlined;

    case ExpenseCategory.entertainment:
      return Icons.movie_outlined;

    case ExpenseCategory.health:
      return Icons.favorite_outline;

    case ExpenseCategory.education:
      return Icons.school_outlined;

    case ExpenseCategory.other:
      return Icons.category_outlined;
  }
}

Color expenseCategoryColor(ExpenseCategory category) {
  switch (category) {
    case ExpenseCategory.food:
      return const Color(0xFFE67E22);

    case ExpenseCategory.transport:
      return const Color(0xFF3498DB);

    case ExpenseCategory.services:
      return const Color(0xFF8E44AD);

    case ExpenseCategory.entertainment:
      return const Color(0xFFE91E63);

    case ExpenseCategory.health:
      return const Color(0xFFE74C3C);

    case ExpenseCategory.education:
      return const Color(0xFF16A085);

    case ExpenseCategory.other:
      return const Color(0xFF7F8C8D);
  }
}
