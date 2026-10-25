# Pagos, recordatorios y Amazon

## Comportamiento actual

- Los pagos siempre se guardan en FinTrack.
- Google Calendar está desactivado por defecto.
- FinTrack muestra avisos dentro de la app para pagos vencidos, de hoy, de mañana y de los próximos 3 días.
- Google Calendar puede habilitarse en una compilación Android futura con `--dart-define=ENABLE_GOOGLE_CALENDAR=true` después de completar OAuth.
- En una compilación Amazon (`AMAZON_BUILD=true`) Google Sign-In y Google Calendar permanecen desactivados.

## Desarrollo Android normal

```powershell
flutter run -d ID_DEL_DISPOSITIVO
```

## Android con Google Calendar habilitado en el futuro

```powershell
flutter run -d ID_DEL_DISPOSITIVO --dart-define=ENABLE_GOOGLE_CALENDAR=true
```

## Amazon / Fire OS

```powershell
.\scripts\build_amazon_release.ps1
```

Los recordatorios incluidos en este parche son avisos dentro de FinTrack y no requieren Google Play Services ni permisos adicionales de notificaciones.
