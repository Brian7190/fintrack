import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/admin_user_budget.dart';
import '../../domain/admin_user_summary.dart';
import '../../domain/repositories/admin_repository.dart';

class FirestoreAdminRepository implements AdminRepository {
  final FirebaseFirestore _firestore;

  FirestoreAdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // ====================================================
  // USUARIOS
  // ====================================================

  @override
  Stream<List<AdminUserSummary>> watchUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      final users = snapshot.docs.map((document) {
        final data = document.data();

        final createdAt = data['createdAt'];
        final lastLogin = data['lastLogin'];

        return AdminUserSummary(
          uid: document.id,
          name: data['name'] as String? ?? 'Sin nombre',
          email: data['email'] as String? ?? '',
          role: data['role'] as String? ?? 'user',
          createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
          lastLogin: lastLogin is Timestamp ? lastLogin.toDate() : null,
          loginCount: (data['loginCount'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      // Ordenamos por actividad más reciente.
      users.sort((a, b) {
        final dateA = a.lastLogin ?? a.createdAt ?? DateTime(2000);

        final dateB = b.lastLogin ?? b.createdAt ?? DateTime(2000);

        return dateB.compareTo(dateA);
      });

      return users;
    });
  }

  // ====================================================
  // PRESUPUESTO ACTUAL DE UN USUARIO
  // ====================================================

  @override
  Stream<AdminUserBudget?> watchCurrentBudget(String userId) {
    final periodKey = AdminUserBudget.currentPeriodKey();

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('budgets')
        .doc(periodKey)
        .snapshots()
        .map((document) {
          if (!document.exists) {
            return null;
          }

          final data = document.data();

          if (data == null) {
            return null;
          }

          final createdAt = data['createdAt'];
          final updatedAt = data['updatedAt'];

          final now = DateTime.now();

          return AdminUserBudget(
            amount: (data['amount'] as num?)?.toDouble() ?? 0,
            month: (data['month'] as num?)?.toInt() ?? now.month,
            year: (data['year'] as num?)?.toInt() ?? now.year,
            createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
            updatedAt: updatedAt is Timestamp ? updatedAt.toDate() : null,
          );
        });
  }

  // ====================================================
  // TOTAL GASTADO DEL MES ACTUAL
  // ====================================================

  @override
  Stream<double> watchCurrentMonthSpent(String userId) {
    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1);

    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(startOfNextMonth))
        .snapshots()
        .map((snapshot) {
          double total = 0;

          for (final document in snapshot.docs) {
            final data = document.data();

            final amount = data['amount'];

            if (amount is num) {
              total += amount.toDouble();
            }
          }

          return total;
        });
  }
}
