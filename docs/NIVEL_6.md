# Nivel 6 · El registro de las entregas

Nivel jugable desde el selector o al completar el nivel 5. No añade un nivel 7: el diálogo final establece el siguiente objetivo narrativo.

## Recorrido

Recepción → tarjeta → clasificación → registro de las dos entregas → conservación → informe de Continuidad → entrada de archivos → orden de continuar los envíos → llamada al Jefe → copia de registros → alarma → patio de salida.

Seis encuentros finitos: 6, 8, 8, 10, 10 y 6 enemigos. Máximo 48, incluidos tres perros. Cuatro Huecos de clasificación empiezan distraídos y pueden evitarse: si permanecen sin alertar, el jugador puede terminar con 44 bajas. Disparar los alerta; los enemigos despertados deben derrotarse antes de leer el registro. Los evitados se retiran sin sumar bajas al pasar a conservación.

Las llegadas tienen marcador previo y breve aviso. Si Nico ocupa la entrada, el refuerzo cambia al lado opuesto y vuelve a avisar. Los grupos y refuerzos están contados; no existe un generador infinito de enemigos. No se espera un contador después de despejar los encuentros.

## Arte y escenario

Seis fondos propios con entradas y salidas, más atlas transparentes de tarjeta, lector, contenedor de muestras, documentos, teléfono, ordenador, memoria, baliza, portón, pallets y señalización. El teléfono y el ordenador se colocan sobre mesas separadas del fondo. El portón tiene estado cerrado/abierto; la baliza parpadea durante la alarma. Las imágenes no dibujan texto narrativo ni actores mediante código.

Los fondos se enlazan en secciones con bordes mezclados y reflejos moderados. Los obstáculos del camino son sprites separados con colisión, para evitar duplicarlos como pintura del fondo. Nico y enemigos conservan sus animaciones existentes. No llueve visualmente en el interior; se reduce el ambiente de lluvia al entrar.

## Documentos y textos

Archivo editable: `assets/distribution/story.json`. Contiene diálogos con Mara y el Jefe, los cuatro documentos y sus páginas breves. E / Enter avanza o cierra. Tab o «Documentos» abre las pruebas recogidas cuando la zona es segura. La lectura detiene movimiento, ataques, reloj y llegadas pendientes.

Los documentos son obligatorios en orden. El Jefe responde a una llamada iniciada por Nico, después de que este lea la orden. El final conecta la copia de los registros con la futura estación de radio.

## Recursos y guardado

Se conservan cuchillo, pistola y escopeta. Reserva de pistola: máximo 36; reserva de escopeta: máximo 12. Seis cajas de 12 balas, cuatro de 4 cartuchos y tres botiquines. Antes del control hay dos cajas de cada arma; están incluidas en esos totales. Todas se recogen automáticamente. Las posiciones no se reajustan al objetivo inicial.

Los puntos seguros guardan salud, munición, recogidas, tarjeta, documentos, llamada y copia. Se normalizan los identificadores numéricos al leer JSON. No se guardan combates en curso ni se duplica munición al continuar. La dificultad y duración final necesitan valoración durante una partida humana; las pruebas automáticas no acreditan una duración de 12–15 minutos.

## Sistemas

- `distribution_level.gd`: estados de progreso, encuentros, avisos de entrada, sigilo opcional, obstáculos, recursos y puntos seguros. Hereda combate y percepción de los sistemas ya probados.
- `distribution_art.gd`: atlas con límites medidos de alfa y carga de textos.
- `main.gd`: conexión desde nivel 5, diálogo inicial/final y acceso a documentos.
- `ui.gd`: selector de seis rutas, botón Documentos y resultado final.
- `save_game.gd`: validación de niveles anteriores y nuevos estados seguros del nivel 6.

## Pruebas

- `distribution_checks.gd`: rutas de sigilo y combate completo, totales 44/48, tres perros, todas las pruebas narrativas, bloqueo de diálogos, avisos previos, colisiones, guardados leídos desde JSON y final del nivel. Las bajas se controlan para verificar la secuencia.
- `distribution_play_checks.gd`: movimiento y persecución con física activa, cuchillo, pistola, dispersión de escopeta, recogida de los dos tipos de munición, botiquín, paso del nivel 5 al 6, continuar, lectura y pausa.
- `distribution_walk_checks.gd`: recorrido con movimiento físico por los pasos libres de las seis zonas, sin teletransportar al jugador entre obstáculos. Aísla geometría; no representa una partida humana completa.
- Regresión: nivel 5, escena de la radio y conexiones narrativas anteriores.

Todos los comprobadores usan guardados de prueba separados del usuario. Algunos comprobadores heredados reportan recursos pendientes al cerrar el proceso de pruebas; se conservan sus registros de diagnóstico, sin presentarlo como un fallo de progresión.
