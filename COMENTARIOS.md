## Comentarios de Yahir Javier González

La verdad la aplicación me gustó bastante, principalmente por los colores que tiene, 
siento que combinan bien y no se ve tan cargada de cosas. 
También me gustó que todo está bien acomodado y es fácil encontrar las opciones, no tuve tanta dificultad para entender cómo funcionaba.

Una de las funciones que más me gustó fue la de los gastos, ya que puedes agregar cuánto gastaste, 
ponerle un nombre y seleccionar en qué categoría fue. También me gustó que automáticamente se va actualizando 
el dinero que llevas gastado y cuánto te queda de tu presupuesto.

Otra cosa que me gustó fueron las estadísticas, principalmente la gráfica circular 
porque puedes ver en qué estás gastando más dinero. Aunque en la gráfica de barras aparecen números 
como 1 y 2 en la parte de abajo y al principio no entendí muy bien qué significaban, estaría mejor que aparecieran los nombres de las categorías.

**Algunas cosas que encontré:**

- Cuando intenté agregar un próximo pago de Spotify por $50, me apareció un mensaje diciendo que no se pudo guardar ni sincronizar con Google Calendar.
- Después intenté acceder con mi cuenta de Google y apareció un error 403, diciendo que la aplicación todavía no completaba la verificación de Google. Supongo que es porque todavía está en pruebas, pero estaría bien que se pudiera utilizar esa función.
- En el calendario aparecen algunas palabras en inglés como "Select date", "Cancel" y "OK". No es algo que afecte mucho, pero estaría mejor que todo estuviera en español.
- En las estadísticas estaría bien mejorar un poquito los nombres que aparecen debajo de las barras, para entender más rápido cada categoría.

**Mis sugerencias:**

Algo que estaría padre sería agregar una opción para cambiar entre modo oscuro y claro, 
aunque los colores actuales sí son de mi agrado. También estaría bien que cuando el presupuesto esté por acabarse aparezca una advertencia para saber que ya estamos gastando demasiado.

En general me gustó la aplicación, se ve bonita y las funciones que pude probar, como registrar gastos y 
consultar las estadísticas, me parecieron útiles. Lo único que sí me dio problema fue lo de Google Calendar,
porque quería probar cómo se guardaban los pagos y no me dejó. Fuera de eso, siento que está bastante bien y es una aplicación que sí podría servir para llevar un control de nuestros gastos.


# Comentarios Adriana Mendoza Dajui

### 1. Error en el campo de nombre durante el registro

El primer error que encontré fue en el apartado de registro de usuarios. Al ingresar el nombre, la aplicación permite utilizar números y caracteres especiales sin mostrar ninguna advertencia o mensaje de error.

Considero que este campo debería contar con una validación para evitar que se registren nombres con caracteres no permitidos.

### 2. Falta de validación del correo electrónico

En el apartado de correo electrónico, la aplicación permite registrar una dirección de correo que no existe, sin comprobar si realmente es válida o pertenece a un usuario.

Sería recomendable implementar una verificación del correo electrónico para evitar registros con direcciones inexistentes.

### 3. Error al ingresar cantidades de dinero demasiado grandes

Al momento de ingresar un presupuesto con una cantidad demasiado grande, por ejemplo:

`50000000000000000000000000000000000000000000000`

La aplicación presenta problemas en la visualización de la información.

En el apartado de **Gastos**, los números se salen del contenedor y provocan que el texto y otros elementos de la pantalla se deformen, afectando el diseño de la aplicación.

Además, al intentar ingresar al apartado de **Estadísticas** después de registrar esta cantidad, la aplicación se queda trabada y posteriormente se cierra de manera inesperada.

Se recomienda establecer un límite para las cantidades de dinero que se pueden ingresar y mejorar la adaptación de los elementos visuales para evitar que se desconfigure la interfaz.

También sería importante revisar el manejo de cantidades grandes para prevenir el cierre inesperado de la aplicación.

Aquí tienes una versión **más sencilla, clara y directa**, perfecta para decirla en una reunión o enviarla por mensaje sin rodeos técnicos:

---

### Comentarios Edson SanJuan Trejo

"En general me parece que la aplicación va por un buen camino y en lo personal tiene un buen diseno. La combinación de colores se ve muy bien y la parte de registrar gastos y ver las gráficas circulares le da un plus y hace que se vea profecional ademas es muy útil para el usuario.
Sin embargo, viéndolo desde el punto de vista práctico, hay varios detalles que debemos corregir.

 ## Errores que encontre
 * **Proteger las entradas de datos:** Falta poner límites para que el usuario no escriba números gigantescos que rompan la pantalla o hagan que la app se cierre. También hay que cuidar que en el nombre no metan símbolos ni números.
 * **Arreglar la conexión con Google:** Darle prioridad a resolver el error al guardar en Google Calendar y el acceso con la cuenta de Google, ya que es una función muy importante que la gente va a querer usar.
 * **Cuidar los pequeños detalles:** Cambiar las palabras que se quedaron en inglés en el calendario y hacer que la gráfica de barras muestre los nombres de las categorías en lugar de solo números, para que todo se entienda a la primera.
 
 
 En resumen, la app me gusta y funciona bien en lo principal, solo es cuestión de corregir esos pequeños errores para que la experiencia sea completamente fluida."



