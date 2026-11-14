# Nivel 7 · Que se sepa

Acceso: Nueva partida → Nivel 7, o Continuar al Nivel 7 al terminar el nivel 6. El nivel 8 todavía no está disponible.

## Recorrido

Seis zonas: acceso, energía, antena, emisión, servicio y salida al puerto. Cinco encuentros finitos: 7, 7, 9, 11 y 10 enemigos. Total: 31 Huecos, 10 resistentes y 3 perros. Los últimos tres encuentros tienen un segundo grupo cuando quedan dos enemigos. Las entradas se anuncian; si Nico ocupa una entrada, el aviso se mueve y se retrasa la aparición.

E / Enter sirve para activar los equipos y hablar por radio. Hay que acercarse al marcador y a la parte superior del camino. Tab o el botón Instrucciones permite consultar la hoja de envío fuera de combate; después del envío también permite volver a leer su confirmación. Leer o hablar bloquea el movimiento, los ataques, el reloj y las llegadas pendientes.

No hay defensa interminable del ordenador ni barra de descarga. La confirmación se guarda al terminar el diálogo con la central. La siguiente parte consiste en salir con vida y recibir la ruta de evacuación.

## Suministros

Siete cajas de pistola de 12 balas, seis cajas de escopeta de 4 cartuchos y dos botiquines. Todos se recogen al pasar. No hay cajas antes del primer combate. Se mantienen las capacidades y el equipo inicial del nivel 6. No se rellenan reservas automáticamente entre zonas.

## Archivos y sistemas

- `assets/broadcast/story.json`: todos los nuevos diálogos y la hoja de instrucciones; texto editable en UTF-8.
- `assets/broadcast/*.png`: seis fondos finales, objetos transparentes y retrato de la operadora.
- `assets/broadcast/regions.json`: regiones medidas del atlas; no se supone una cuadrícula uniforme.
- `scripts/broadcast_art.gd`: carga y recorte de assets, documentos y diálogos.
- `scripts/broadcast_level.gd`: estados del recorrido, oleadas finitas, equipos, clima exterior, colisiones, suministros y puntos seguros.
- `scenes/level_07.tscn`: entrada del nivel. Reutiliza jugador, combate, enemigos y diálogos existentes.
- `scripts/main.gd`, `ui.gd`, `save_game.gd`: transición desde nivel 6, selector, retrato, resultados y validación del guardado del nivel 7.

Estados seguros: 0, 2, 3, 5, 6, 8, 9, 10, 12, 13, 15. Los estados de combate no se guardan. Energía, antena, recepción y evacuación son indicadores independientes que se validan contra el punto de progreso. Continuar mantiene recursos recogidos y no vuelve a generar grupos terminados.

## Comprobaciones

- `tests/broadcast_checks.gd`: recorrido completo, cinco encuentros, conteos y perros, congelación durante diálogo, texto que cabe en pantalla, retrato, todos los puntos seguros serializados a JSON, menú y final.
- `tests/broadcast_play_checks.gd`: movimiento físico, persecución, pistola, escopeta, cuchillo, colisión de mesa, recogida automática, reservas separadas, Continuar real y pausa.
- `tests/broadcast_walk_checks.gd`: caminata física hasta los objetivos de las seis zonas y salida, aislando geometría del combate.
- Capturas reales de Godot en `docs/screenshots/broadcast_*.png`.

Las pruebas funcionales no equivalen a una partida humana completa: duración y dificultad quedan para la revisión jugable. No se afirma una duración medida de 12–15 minutos.

Resultados: las tres suites nuevas y las regresiones de nivel 6, conexiones narrativas y rescate pasaron sin fallos funcionales. Recorrido y combate también se verificaron desde el proyecto instalado. Algunas ejecuciones de recorrido y rescate emiten avisos de recursos pendientes al cerrar el proceso de prueba; las comprobaciones funcionales pasan, pero no se presenta el cierre de esas pruebas como libre de avisos.

Diseños, prompts y especificación de producción: carpeta de trabajo `outputs/nivel-7`. Imágenes finales producidas con image_gen integrado. Los fondos conservan los diseños aprobados, eliminando equipos y obstáculos que requerían sprites aparte.
