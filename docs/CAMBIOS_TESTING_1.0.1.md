# FinTrack 1.0.1 - Correcciones derivadas de testing

- Los pagos se guardan primero en FinTrack; Google Calendar ya no bloquea el registro.
- En caso de fallo de Calendar se informa que el pago quedó guardado localmente/en Firestore.
- Compilación Amazon (`AMAZON_BUILD=true`) sin Google Sign-In ni Calendar en la interfaz.
- Validación de nombre: evita números y caracteres no válidos.
- Contraseñas nuevas: mínimo 8 caracteres, al menos una letra y un número.
- Nuevas cuentas por correo reciben verificación de email.
- Límite de montos: 99,999,999.99.
- Lectura defensiva de montos inválidos almacenados previamente.
- Advertencia ante posible gasto duplicado exacto en la misma fecha.
- Selector de fechas localizado al español.
- La gráfica de barras muestra etiquetas de categorías.
- Aviso al alcanzar 80% del presupuesto.
- Android Manifest endurecido para release y Fire OS.
- Firma release configurable mediante `android/key.properties`.
- Script de build AAB para Amazon Appstore.
