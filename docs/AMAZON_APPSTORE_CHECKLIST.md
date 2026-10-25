# FinTrack - Checklist Amazon Appstore (Fire OS)

## Estado del código

- [x] Los pagos se guardan en FinTrack aunque falle Google Calendar.
- [x] La compilación Amazon desactiva Google Sign-In y Google Calendar con `--dart-define=AMAZON_BUILD=true`.
- [x] Firebase Authentication y Cloud Firestore permanecen como núcleo de datos.
- [x] Validación de nombres, contraseñas y cantidades monetarias.
- [x] Límite de cantidades para evitar desbordamientos y cierres inesperados.
- [x] Selector de fecha en español.
- [x] Etiquetas legibles en la gráfica de barras.
- [x] Aviso al llegar al 80% del presupuesto.
- [x] Advertencia ante un posible gasto duplicado.
- [x] Manifest con INTERNET, nombre FinTrack, tráfico claro deshabilitado y backup deshabilitado.
- [x] Preparación para firma release mediante `android/key.properties`.

## Antes de enviar a Amazon

- [ ] Crear keystore de producción y completar `android/key.properties`.
- [ ] Ejecutar `scripts/build_amazon_release.ps1`.
- [ ] Probar el AAB/APK resultante en un Fire Tablet físico.
- [ ] Confirmar que registro/login por correo funciona sin Google Play Services.
- [ ] Confirmar que gastos, presupuesto, estadísticas y pagos funcionan en Fire OS.
- [ ] Publicar una política de privacidad accesible por URL.
- [ ] Publicar una página web para solicitar eliminación de cuenta/datos.
- [ ] Completar Privacy Labels en Amazon Developer Console.
- [ ] Proporcionar credenciales de prueba a Amazon si la app requiere login.
- [ ] Preparar icono, capturas y material gráfico de la ficha.
- [ ] Revisar clasificación de contenido y disponibilidad por regiones.

## Build para Amazon

```powershell
.\scripts\build_amazon_release.ps1
```

El archivo esperado es:

`build\app\outputs\bundle\release\app-release.aab`

> Importante: Amazon Appstore ya no recibe nuevas apps para teléfonos Android genéricos. Esta preparación está orientada a Fire OS / Fire Tablet.
