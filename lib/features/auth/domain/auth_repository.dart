import 'app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  });

  Future<AppUser> signIn({required String email, required String password});

  Future<void> signOut();

  Future<AppUser?> getCurrentUser();
}
