import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      return _getUserProfile(firebaseUser.uid);
    });
  }

  @override
  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('No se pudo crear el usuario.');
    }

    final now = DateTime.now();

    final userData = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'role': 'user',
      'createdAt': Timestamp.fromDate(now),
      'lastLogin': Timestamp.fromDate(now),
      'loginCount': 1,
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

    return AppUser(
      uid: firebaseUser.uid,
      name: name.trim(),
      email: email.trim().toLowerCase(),
      role: 'user',
      createdAt: now,
      lastLogin: now,
      loginCount: 1,
    );
  }

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('No se pudo iniciar sesión.');
    }

    final userRef = _firestore.collection('users').doc(firebaseUser.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        return;
      }

      final data = snapshot.data()!;

      final currentCount = (data['loginCount'] as num?)?.toInt() ?? 0;

      transaction.update(userRef, {
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': currentCount + 1,
      });
    });

    final user = await _getUserProfile(firebaseUser.uid);

    if (user == null) {
      throw Exception('No se encontró el perfil del usuario.');
    }

    return user;
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    return _getUserProfile(firebaseUser.uid);
  }

  Future<AppUser?> _getUserProfile(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    final data = snapshot.data()!;

    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

    final lastLogin = (data['lastLogin'] as Timestamp?)?.toDate();

    return AppUser(
      uid: uid,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: data['role'] as String? ?? 'user',
      createdAt: createdAt,
      lastLogin: lastLogin,
      loginCount: (data['loginCount'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<void> signOut() {
    return _auth.signOut();
  }
}
