import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/router.dart';
import 'features/auth/data/session_preferences.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ====================================================
  // FIREBASE
  // ====================================================

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ====================================================
  // SESIÓN GUARDADA
  // ====================================================

  final firebaseUser = await FirebaseAuth.instance.authStateChanges().first;

  final rememberSession = await SessionPreferences.getRememberSession();

  // Si existe una sesión de Firebase pero el usuario
  // no pidió conservarla, cerramos la sesión.
  if (!rememberSession && firebaseUser != null) {
    await FirebaseAuth.instance.signOut();
  }

  // ====================================================
  // RUTA INICIAL
  // ====================================================

  final currentUser = FirebaseAuth.instance.currentUser;

  if (rememberSession && currentUser != null) {
    appRouter.go(AppRoutes.home);
  } else {
    appRouter.go(AppRoutes.login);
  }

  // ====================================================
  // APP
  // ====================================================

  runApp(const ProviderScope(child: FinTrackApp()));
}
