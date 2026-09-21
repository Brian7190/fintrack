import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/expense.dart';
import '../../domain/expense_category.dart';
import '../../domain/repositories/expense_repository.dart';

class FirestoreExpenseRepository implements ExpenseRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FirestoreExpenseRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesCollection {
    return _firestore.collection('users').doc(userId).collection('expenses');
  }

  @override
  Stream<List<Expense>> watchExpenses() {
    return _expensesCollection.snapshots().map((snapshot) {
      final expenses = snapshot.docs.map((document) {
        return _fromFirestore(document);
      }).toList();

      expenses.sort((a, b) => b.date.compareTo(a.date));

      return expenses;
    });
  }

  @override
  Future<void> addExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).set({
      'name': expense.name,
      'amount': expense.amount,
      'category': expense.category.name,
      'date': Timestamp.fromDate(expense.date),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await _expensesCollection.doc(expense.id).update({
      'name': expense.name,
      'amount': expense.amount,
      'category': expense.category.name,
      'date': Timestamp.fromDate(expense.date),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expensesCollection.doc(id).delete();
  }

  Expense _fromFirestore(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? <String, dynamic>{};

    final categoryName = data['category'] as String? ?? '';

    final category = ExpenseCategory.values.firstWhere(
      (item) => item.name == categoryName,
      orElse: () => ExpenseCategory.other,
    );

    final rawDate = data['date'];

    DateTime date;

    if (rawDate is Timestamp) {
      date = rawDate.toDate();
    } else {
      date = DateTime.now();
    }

    return Expense(
      id: document.id,
      name: data['name'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      date: date,
      category: category,
    );
  }
}
