import 'dart:async';

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

import '../../core/app_config.dart';

class CalendarConnectionRequiredException implements Exception {
  const CalendarConnectionRequiredException();

  @override
  String toString() {
    return 'Debes conectar tu cuenta de Google Calendar.';
  }
}

class CalendarService {
  CalendarService._();

  static const String _webClientId =
      '825635816619-24tuam6156a50ndf4nao6ru7lfoonrrv.apps.googleusercontent.com';

  static const List<String> _scopes = [
    calendar.CalendarApi.calendarEventsScope,
  ];

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static GoogleSignInAccount? _currentGoogleUser;

  static final StreamController<GoogleSignInAccount?> _accountController =
      StreamController<GoogleSignInAccount?>.broadcast();

  static StreamSubscription<GoogleSignInAuthenticationEvent>?
  _authenticationSubscription;

  static Future<void>? _initializationFuture;

  // ====================================================
  // ESTADO
  // ====================================================

  static GoogleSignInAccount? get currentGoogleUser => _currentGoogleUser;

  static bool get isConnected => _currentGoogleUser != null;

  static Stream<GoogleSignInAccount?> get accountChanges =>
      _accountController.stream;

  // ====================================================
  // INICIALIZAR
  // ====================================================

  static Future<void> initialize() {
    _initializationFuture ??= _initializeInternal();

    return _initializationFuture!;
  }

  static Future<void> _initializeInternal() async {
    if (!AppConfig.googleIntegrationsEnabled) {
      throw UnsupportedError(
        'Google Calendar no está disponible en esta versión de FinTrack.',
      );
    }

    await _googleSignIn.initialize(
      // En Web usamos el Client ID Web.
      clientId: kIsWeb ? _webClientId : null,

      // Android utiliza el Client ID Web
      // como serverClientId.
      serverClientId: kIsWeb ? null : _webClientId,
    );

    _authenticationSubscription ??= _googleSignIn.authenticationEvents.listen(
      (event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _setCurrentUser(event.user);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _setCurrentUser(null);
        }
      },
      onError: (_) {
        _setCurrentUser(null);
      },
    );

    // Intenta recuperar silenciosamente una cuenta
    // que ya se haya usado.
    final lightweight = _googleSignIn.attemptLightweightAuthentication();

    if (lightweight != null) {
      final account = await lightweight;

      if (account != null) {
        _setCurrentUser(account);
      }
    }
  }

  static void _setCurrentUser(GoogleSignInAccount? account) {
    _currentGoogleUser = account;
    _accountController.add(account);
  }

  // ====================================================
  // OBTENER CUENTA
  // ====================================================

  static Future<GoogleSignInAccount> _getGoogleAccount() async {
    await initialize();

    if (_currentGoogleUser != null) {
      return _currentGoogleUser!;
    }

    // Web NO permite authenticate().
    // Debe usarse el botón oficial de Google.
    if (kIsWeb) {
      throw const CalendarConnectionRequiredException();
    }

    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'Google Sign-In no está disponible en esta plataforma.',
      );
    }

    final account = await _googleSignIn.authenticate(scopeHint: _scopes);

    _setCurrentUser(account);

    return account;
  }

  // ====================================================
  // API DE CALENDAR
  // ====================================================

  static Future<T> _withCalendarApi<T>(
    Future<T> Function(calendar.CalendarApi api) operation,
  ) async {
    final user = await _getGoogleAccount();

    var authorization = await user.authorizationClient.authorizationForScopes(
      _scopes,
    );

    authorization ??= await user.authorizationClient.authorizeScopes(_scopes);

    final client = authorization.authClient(scopes: _scopes);

    try {
      final api = calendar.CalendarApi(client);

      return await operation(api);
    } finally {
      client.close();
    }
  }

  // ====================================================
  // EVENTO
  // ====================================================

  static calendar.Event _buildEvent({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) {
    final startDate = DateTime.utc(dueDate.year, dueDate.month, dueDate.day);

    final endDate = startDate.add(const Duration(days: 1));

    return calendar.Event(
      summary: 'Pago: $name',
      description:
          'Pago registrado en FinTrack.\n'
          'Monto: \$${amount.toStringAsFixed(2)} MXN.',
      start: calendar.EventDateTime(date: startDate),
      end: calendar.EventDateTime(date: endDate),
    );
  }

  // ====================================================
  // CREAR
  // ====================================================

  static Future<String> createEvent({
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    return _withCalendarApi<String>((api) async {
      final event = _buildEvent(name: name, amount: amount, dueDate: dueDate);

      final created = await api.events.insert(event, 'primary');

      final eventId = created.id;

      if (eventId == null || eventId.isEmpty) {
        throw StateError('Google Calendar no devolvió un ID de evento.');
      }

      return eventId;
    });
  }

  // ====================================================
  // ACTUALIZAR
  // ====================================================

  static Future<void> updateEvent({
    required String eventId,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    await _withCalendarApi<void>((api) async {
      final event = _buildEvent(name: name, amount: amount, dueDate: dueDate);

      await api.events.update(event, 'primary', eventId);
    });
  }

  // ====================================================
  // ELIMINAR
  // ====================================================

  static Future<void> deleteEvent({required String eventId}) async {
    await _withCalendarApi<void>((api) async {
      await api.events.delete('primary', eventId);
    });
  }
}
