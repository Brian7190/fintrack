import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/admin_user_budget.dart';

import '../data/repositories/firestore_admin_repository.dart';
import '../domain/admin_user_summary.dart';
import '../domain/repositories/admin_repository.dart';

// ====================================================
// REPOSITORIO
// ====================================================

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return FirestoreAdminRepository();
});

// ====================================================
// LISTA DE USUARIOS
// ====================================================

final adminUsersProvider = StreamProvider<List<AdminUserSummary>>((ref) {
  return ref.watch(adminRepositoryProvider).watchUsers();
});

// ====================================================
// TOTAL DE USUARIOS REGISTRADOS
// No contamos las cuentas administrador.
// ====================================================

final totalRegisteredUsersProvider = Provider<int>((ref) {
  final asyncUsers = ref.watch(adminUsersProvider);

  final users = asyncUsers.asData?.value;

  if (users == null) {
    return 0;
  }

  return users.where((user) => !user.isAdmin).length;
});

// ====================================================
// TOTAL DE INICIOS DE SESIÓN
// ====================================================

final totalLoginCountProvider = Provider<int>((ref) {
  final asyncUsers = ref.watch(adminUsersProvider);

  final users = asyncUsers.asData?.value;

  if (users == null) {
    return 0;
  }

  return users.fold<int>(0, (total, user) => total + user.loginCount);
});

// ====================================================
// USUARIOS QUE YA HAN INICIADO SESIÓN
// ====================================================

final usersWithLoginProvider = Provider<int>((ref) {
  final asyncUsers = ref.watch(adminUsersProvider);

  final users = asyncUsers.asData?.value;

  if (users == null) {
    return 0;
  }

  return users.where((user) => !user.isAdmin && user.loginCount > 0).length;
});

// ====================================================
// USUARIO MÁS RECIENTE
// ====================================================

final mostRecentUserProvider = Provider<AdminUserSummary?>((ref) {
  final asyncUsers = ref.watch(adminUsersProvider);

  final users = asyncUsers.asData?.value;

  if (users == null || users.isEmpty) {
    return null;
  }

  final normalUsers = users.where((user) => !user.isAdmin).toList();

  if (normalUsers.isEmpty) {
    return null;
  }

  normalUsers.sort((a, b) {
    final dateA = a.lastLogin ?? a.createdAt ?? DateTime(2000);

    final dateB = b.lastLogin ?? b.createdAt ?? DateTime(2000);

    return dateB.compareTo(dateA);
  });

  return normalUsers.first;
});

// ====================================================
// PRESUPUESTO ACTUAL DE UN USUARIO
// ====================================================

final adminUserBudgetProvider = StreamProvider.family<AdminUserBudget?, String>(
  (ref, userId) {
    return ref.watch(adminRepositoryProvider).watchCurrentBudget(userId);
  },
);

// ====================================================
// BUSCAR USUARIO POR UID
// ====================================================

final adminUserByIdProvider = Provider.family<AdminUserSummary?, String>((
  ref,
  userId,
) {
  final asyncUsers = ref.watch(adminUsersProvider);

  final users = asyncUsers.asData?.value;

  if (users == null) {
    return null;
  }

  for (final user in users) {
    if (user.uid == userId) {
      return user;
    }
  }

  return null;
});
// ====================================================
// GASTADO DEL MES POR USUARIO
// ====================================================

final adminUserSpentProvider = StreamProvider.family<double, String>((
  ref,
  userId,
) {
  return ref.watch(adminRepositoryProvider).watchCurrentMonthSpent(userId);
});
