import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../core/app_config.dart';
import '../data/session_preferences.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberSession = false;

  @override
  void initState() {
    super.initState();

    _loadRememberPreference();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  // ====================================================
  // CARGAR PREFERENCIA DE SESIÓN
  // ====================================================

  Future<void> _loadRememberPreference() async {
    final rememberSession = await SessionPreferences.getRememberSession();

    if (!mounted) {
      return;
    }

    setState(() {
      _rememberSession = rememberSession;
    });
  }

  // ====================================================
  // VALIDAR CORREO
  // ====================================================

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Ingresa tu correo electrónico';
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      return 'Ingresa un correo válido';
    }

    return null;
  }

  // ====================================================
  // VALIDAR CONTRASEÑA
  // ====================================================

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa tu contraseña';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }

    return null;
  }

  // ====================================================
  // LOGIN CON CORREO Y CONTRASEÑA
  // ====================================================

  Future<void> _login() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid || _isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);

      await repository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      await SessionPreferences.setRememberSession(_rememberSession);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      context.go(AppRoutes.home);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_firebaseMessage(error));
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('No fue posible iniciar sesión. Inténtalo nuevamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ====================================================
  // LOGIN CON GOOGLE
  // ====================================================

  Future<void> _loginWithGoogle() async {
    if (_isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(authRepositoryProvider);

      await repository.signInWithGoogle();

      await SessionPreferences.setRememberSession(_rememberSession);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      context.go(AppRoutes.home);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      _showError(_firebaseMessage(error));
    } catch (_) {
      if (!mounted) {
        return;
      }

      _showError('No fue posible iniciar sesión con Google.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ====================================================
  // MENSAJES DE FIREBASE
  // ====================================================

  String _firebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'El correo o la contraseña son incorrectos.';

      case 'user-not-found':
        return 'No existe una cuenta registrada con este correo.';

      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'user-disabled':
        return 'Esta cuenta se encuentra deshabilitada.';

      case 'too-many-requests':
        return 'Se realizaron demasiados intentos. Espera un momento e inténtalo nuevamente.';

      case 'network-request-failed':
        return 'No se pudo conectar con Firebase. Revisa tu conexión a Internet.';

      case 'account-exists-with-different-credential':
        return 'Ya existe una cuenta con este correo utilizando otro método de inicio de sesión.';

      case 'credential-already-in-use':
        return 'Esta cuenta de Google ya está vinculada a otro usuario.';

      case 'popup-closed-by-user':
        return 'Se cerró la ventana de Google antes de completar el inicio de sesión.';

      case 'popup-blocked':
        return 'El navegador bloqueó la ventana de inicio de sesión de Google.';

      case 'operation-not-allowed':
        return 'El inicio de sesión con Google no está habilitado en Firebase.';

      case 'google-id-token-missing':
        return 'Google no pudo completar la autenticación. Inténtalo nuevamente.';

      case 'email-not-verified':
        return 'Verifica tu correo electrónico antes de iniciar sesión. Te enviamos un enlace de verificación.';

      default:
        return 'No fue posible iniciar sesión. (${error.code})';
    }
  }

  // ====================================================
  // MOSTRAR ERROR
  // ====================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ====================================================
  // BUILD
  // ====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // =====================================
                    // LOGO FINTRACK
                    // =====================================
                    Container(
                      width: 92,
                      height: 92,
                      decoration: const BoxDecoration(
                        color: AppColors.primarySoft,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.insert_chart_outlined,
                        size: 48,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =====================================
                    // NOMBRE
                    // =====================================
                    const Text(
                      'FinTrack',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      'Administra tus gastos y controla tu presupuesto',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),

                    const SizedBox(height: 36),

                    // =====================================
                    // CORREO
                    // =====================================
                    TextFormField(
                      controller: _emailController,
                      enabled: !_isLoading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.email],
                      validator: _validateEmail,
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =====================================
                    // CONTRASEÑA
                    // =====================================
                    TextFormField(
                      controller: _passwordController,
                      enabled: !_isLoading,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enableSuggestions: false,
                      autocorrect: false,
                      autofillHints: const [AutofillHints.password],
                      validator: _validatePassword,
                      onFieldSubmitted: (_) {
                        _login();
                      },
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscurePassword
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =====================================
                    // MANTENER SESIÓN
                    // =====================================
                    Material(
                      color: AppColors.surfaceAlt,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CheckboxListTile(
                        value: _rememberSession,
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                setState(() {
                                  _rememberSession = value ?? false;
                                });
                              },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 2,
                        ),
                        title: const Text(
                          'Mantener sesión iniciada',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Accede automáticamente la próxima vez.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =====================================
                    // BOTÓN LOGIN NORMAL
                    // =====================================
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Iniciar sesión'),
                      ),
                    ),

                    if (AppConfig.googleIntegrationsEnabled) ...[
                      const SizedBox(height: 20),

                      const Row(
                        children: [
                          Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 14),
                            child: Text(
                              'o',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          Expanded(child: Divider()),
                        ],
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : _loginWithGoogle,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Continuar con Google',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),
                    ] else
                      const SizedBox(height: 18),

                    // =====================================
                    // REGISTRO
                    // =====================================
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        const Text(
                          '¿No tienes una cuenta?',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  context.push(AppRoutes.register);
                                },
                          child: const Text('Regístrate'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
