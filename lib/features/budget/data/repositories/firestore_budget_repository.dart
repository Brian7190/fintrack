import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/monthly_budget.dart';
import '../../domain/repositories/budget_repository.dart';

class FirestoreBudgetRepository implements BudgetRepository {
  final FirebaseFirestore _firestore;
  final String userId;

  FirestoreBudgetRepository({
    required this.userId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _budgetsCollection {
    return _firestore.collection('users').doc(userId).collection('budgets');
  }

  @override
  Stream<List<MonthlyBudget>> watchBudgets() {
    return _budgetsCollection.snapshots().map((snapshot) {
      final budgets = snapshot.docs.map((document) {
        return _fromFirestore(document);
      }).toList();

      budgets.sort((a, b) {
        final dateA = DateTime(a.year, a.month);

        final dateB = DateTime(b.year, b.month);

        return dateB.compareTo(dateA);
      });

      return budgets;
    });
  }

  @override
  Future<void> saveBudget(MonthlyBudget budget) async {
    await _budgetsCollection.doc(budget.periodKey).set({
      'amount': budget.amount,
      'month': budget.month,
      'year': budget.year,
      'createdAt': Timestamp.fromDate(budget.createdAt),
      'updatedAt': Timestamp.fromDate(budget.updatedAt),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteBudget(String periodKey) async {
    await _budgetsCollection.doc(periodKey).delete();
  }

  MonthlyBudget _fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final now = DateTime.now();

    final createdAt = data['createdAt'];

    final updatedAt = data['updatedAt'];

    return MonthlyBudget(
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      month: (data['month'] as num?)?.toInt() ?? now.month,
      year: (data['year'] as num?)?.toInt() ?? now.year,
      createdAt: createdAt is Timestamp ? createdAt.toDate() : now,
      updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : now,
    );
  }
}
