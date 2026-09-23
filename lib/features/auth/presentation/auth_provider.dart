import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/firebase_auth_repository.dart';
import '../domain/app_user.dart';
import '../domain/auth_repository.dart';

// ====================================================
// REPOSITORIO DE AUTENTICACIÓN
// ====================================================

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// ====================================================
// ESTADO DE AUTENTICACIÓN
// ====================================================

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

// ====================================================
// PERFIL ACTUAL EN FIRESTORE
// Escucha cambios del documento del usuario.
// ====================================================

final currentUserProfileProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);

  final authenticatedUser = authState.asData?.value;

  if (authenticatedUser == null) {
    return Stream.value(null);
  }

  return FirebaseFirestore.instance
      .collection('users')
      .doc(authenticatedUser.uid)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          return null;
        }

        final data = snapshot.data();

        if (data == null) {
          return null;
        }

        final createdAt = data['createdAt'];

        final lastLogin = data['lastLogin'];

        return AppUser(
          uid: snapshot.id,
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          role: data['role'] as String? ?? 'user',
          createdAt: createdAt is Timestamp
              ? createdAt.toDate()
              : DateTime.now(),
          lastLogin: lastLogin is Timestamp ? lastLogin.toDate() : null,
          loginCount: (data['loginCount'] as num?)?.toInt() ?? 0,
        );
      });
});

// ====================================================
// ¿ES ADMINISTRADOR?
// ====================================================

final isAdminProvider = Provider<bool>((ref) {
  final profile = ref.watch(currentUserProfileProvider);

  return profile.asData?.value?.isAdmin ?? false;
});
