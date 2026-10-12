# FinTrack

FinTrack es una aplicación desarrollada en Flutter para ayudar a los usuarios a administrar sus finanzas personales.

Permite registrar gastos, establecer un presupuesto mensual, consultar estadísticas, registrar próximos pagos, iniciar sesión con correo o Google y mantener la información separada por usuario mediante Firebase.

También cuenta con un panel administrativo y una integración inicial con Google Calendar.

## Tecnologías utilizadas

- Flutter
- Dart
- Firebase Authentication
- Cloud Firestore
- Riverpod
- GoRouter
- Shared Preferences
- Google Sign-In
- Google Calendar
- Git
- GitHub

## Dependencias principales

flutter_riverpod: ^3.4.3
intl: ^0.20.2
fl_chart: ^1.2.0
go_router: 17.5.0
firebase_core: ^4.15.0
firebase_auth: ^6.7.0
cloud_firestore: ^6.10.0
shared_preferences: ^2.5.5
url_launcher: ^6.3.3
google_sign_in: ^7.2.0
googleapis: ^17.0.0
http: ^1.6.0
extension_google_sign_in_as_googleapis_auth: ^3.0.0
google_sign_in_web: ^1.1.3

## Ejecutar el proyecto

Instalar las dependencias:
flutter pub get

Ejecutar la aplicación:
flutter run

Ejecutar en Chrome:
flutter run -d chrome

Consultar dispositivos disponibles:
flutter devices

Ejecutar en un dispositivo Android:
flutter run -d ID_DEL_DISPOSITIVO

## Verificación del proyecto

dart format lib
flutter analyze
flutter test

## Generar iconos

dart run flutter_launcher_icons

## Configuración de Firebase

flutterfire configure

## Control de versiones

git status
git add .
git commit -m "mensaje"
git push origin fintrackv1

## Versión

v1.0.0

Proyecto desarrollado con fines académicos.