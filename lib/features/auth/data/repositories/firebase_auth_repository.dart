import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/app_config.dart';

import '../../domain/app_user.dart';
import '../../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Client ID Web creado en Google Auth Platform.
  //
  // En Android se utiliza como serverClientId.
  static const String _googleWebClientId =
      '825635816619-24tuam6156a50ndf4nao6ru7lfoonrrv.apps.googleusercontent.com';

  static bool _googleInitialized = false;

  FirebaseAuthRepository({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  // ====================================================
  // CAMBIOS DE AUTENTICACIÓN
  // ====================================================

  @override
  Stream<AppUser?> authStateChanges() {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }

      return _getUserProfile(firebaseUser.uid);
    });
  }

  // ====================================================
  // REGISTRO CORREO / CONTRASEÑA
  // ====================================================

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
      'requiresEmailVerification': true,
    };

    await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

    await firebaseUser.sendEmailVerification();

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

  // ====================================================
  // LOGIN CORREO / CONTRASEÑA
  // ====================================================

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

    final profileSnapshot = await _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    final requiresEmailVerification =
        profileSnapshot.data()?['requiresEmailVerification'] == true;

    if (requiresEmailVerification && !firebaseUser.emailVerified) {
      try {
        await firebaseUser.sendEmailVerification();
      } catch (_) {
        // Evita ocultar el mensaje principal si Firebase limita el reenvío.
      }

      await _auth.signOut();

      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Debes verificar tu correo antes de iniciar sesión.',
      );
    }

    await _updateLoginInformation(firebaseUser.uid);

    final user = await _getUserProfile(firebaseUser.uid);

    if (user == null) {
      throw Exception('No se encontró el perfil del usuario.');
    }

    return user;
  }

  // ====================================================
  // LOGIN CON GOOGLE
  // ====================================================

  @override
  Future<AppUser> signInWithGoogle() async {
    if (!AppConfig.googleIntegrationsEnabled) {
      throw UnsupportedError(
        'El inicio de sesión con Google no está disponible en esta versión.',
      );
    }

    late final UserCredential credential;

    // ==================================================
    // WEB
    // ==================================================

    if (kIsWeb) {
      final provider = GoogleAuthProvider();

      provider.setCustomParameters({
        // Fuerza a mostrar selección de cuenta.
        'prompt': 'select_account',
      });

      credential = await _auth.signInWithPopup(provider);
    }
    // ==================================================
    // ANDROID / iOS
    // ==================================================
    else {
      final googleSignIn = GoogleSignIn.instance;

      if (!_googleInitialized) {
        await googleSignIn.initialize(serverClientId: _googleWebClientId);

        _googleInitialized = true;
      }

      final googleUser = await googleSignIn.authenticate();

      final googleAuth = googleUser.authentication;

      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'google-id-token-missing',
          message: 'Google no devolvió un token de autenticación.',
        );
      }

      final googleCredential = GoogleAuthProvider.credential(idToken: idToken);

      credential = await _auth.signInWithCredential(googleCredential);
    }

    final firebaseUser = credential.user;

    if (firebaseUser == null) {
      throw Exception('No fue posible iniciar sesión con Google.');
    }

    // ==================================================
    // PERFIL FIRESTORE
    // ==================================================

    return _createOrUpdateGoogleProfile(firebaseUser);
  }

  // ====================================================
  // CREAR O ACTUALIZAR PERFIL DE GOOGLE
  // ====================================================

  Future<AppUser> _createOrUpdateGoogleProfile(User firebaseUser) async {
    final userRef = _firestore.collection('users').doc(firebaseUser.uid);

    final now = DateTime.now();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      // ==============================================
      // NUEVO USUARIO
      // ==============================================

      if (!snapshot.exists) {
        transaction.set(userRef, {
          'name': firebaseUser.displayName ?? '',
          'email': firebaseUser.email?.trim().toLowerCase() ?? '',
          'role': 'user',
          'createdAt': Timestamp.fromDate(now),
          'lastLogin': Timestamp.fromDate(now),
          'loginCount': 1,
        });

        return;
      }

      // ==============================================
      // USUARIO EXISTENTE
      // ==============================================

      final data = snapshot.data()!;

      final currentCount = (data['loginCount'] as num?)?.toInt() ?? 0;

      transaction.update(userRef, {
        'lastLogin': FieldValue.serverTimestamp(),
        'loginCount': currentCount + 1,
      });
    });

    final profile = await _getUserProfile(firebaseUser.uid);

    if (profile == null) {
      throw Exception('No fue posible cargar el perfil del usuario.');
    }

    return profile;
  }

  // ====================================================
  // ACTUALIZAR INFORMACIÓN DE LOGIN
  // ====================================================

  Future<void> _updateLoginInformation(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

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
  }

  // ====================================================
  // USUARIO ACTUAL
  // ====================================================

  @override
  Future<AppUser?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;

    if (firebaseUser == null) {
      return null;
    }

    return _getUserProfile(firebaseUser.uid);
  }

  // ====================================================
  // PERFIL DESDE FIRESTORE
  // ====================================================

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

  // ====================================================
  // CERRAR SESIÓN
  // ====================================================

  @override
  Future<void> signOut() async {
    await _auth.signOut();

    // GoogleSignIn no se utiliza en Web porque Firebase
    // maneja allí el popup directamente.
    if (!kIsWeb && _googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Si no había una sesión de Google activa,
        // Firebase igualmente ya cerró la sesión.
      }
    }
  }
}
