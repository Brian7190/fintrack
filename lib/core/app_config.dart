class AppConfig {
  AppConfig._();

  /// Build pensado para Amazon Fire OS.
  ///
  /// Compilar con:
  /// flutter build appbundle --release --dart-define=AMAZON_BUILD=true
  static const bool isAmazonBuild = bool.fromEnvironment(
    'AMAZON_BUILD',
    defaultValue: false,
  );

  /// Google Sign-In puede mantenerse en la versión Android normal.
  /// En Amazon/Fire OS se oculta porque Fire OS no incluye Google Play
  /// Services de forma nativa.
  static const bool googleSignInEnabled = !isAmazonBuild;

  /// Google Calendar queda desactivado por defecto. Esto evita que la app
  /// dependa de OAuth/Google Play Services para registrar un pago.
  ///
  /// Si en el futuro se completa la configuración y verificación OAuth, se
  /// puede habilitar en una compilación Android normal con:
  /// --dart-define=ENABLE_GOOGLE_CALENDAR=true
  ///
  /// En Amazon siempre permanece desactivado.
  static const bool googleCalendarEnabled =
      !isAmazonBuild &&
      bool.fromEnvironment('ENABLE_GOOGLE_CALENDAR', defaultValue: false);

  /// Alias conservado para no romper pantallas existentes que solo necesitan
  /// saber si Google Sign-In está disponible.
  static const bool googleIntegrationsEnabled = googleSignInEnabled;
}
