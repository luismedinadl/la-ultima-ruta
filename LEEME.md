# The Last Route — Niveles 1, 2 y 3

Nivel 3 disponible en Nueva partida → Nivel 3 · Bajo la ciudad, o desde los resultados del Nivel 2. [Guía del metro](docs/NIVEL_3.md).

# The Last Route — Niveles 1 y 2 jugables

Ruta compacta: inicio → Local 24 → cruce → entrega, con 50 metros (1000 píxeles) entre puntos. El mapa se ha acortado físicamente; las partidas antiguas se adaptan conservando salud, bajas y progreso. Las duraciones históricas de la ruta larga no corresponden a esta versión.

Proyecto Godot 4. Probado con Godot 4.7.2 y renderizador Compatibility en Windows.

## Jugar

Ejecuta **Jugar.cmd**, o abre **project.godot** en Godot y pulsa **F5**.
El lanzador usa la instalación de Godot de este equipo; también admite la variable GODOT_BIN.
No es un ejecutable independiente: necesita Godot instalado. Las plantillas de exportación Windows no están instaladas en este equipo.

- WASD o flechas: movimiento.
- Espacio: arma equipada (pistola con asistencia de apuntado o cuchillo).
- Clic izquierdo: disparar hacia el cursor. R: recargar. Q: cambiar arma.
- Munición: pasar sobre las cajas.
- E o Enter: interacción y diálogo. Una pulsación completa el texto; otra avanza.
- Escape: pausa. El reloj, los enemigos y el jugador se detienen.

## Contenido

- Menú cinematográfico con Nueva partida, Continuar, Controles y Salir.
- Retratos, diálogos iniciales/finales y bloqueo de acciones durante diálogo.
- Nico con siete acciones y ocho orientaciones; zombi con cinco acciones y ocho orientaciones.
- Cuchillo con anticipación, impacto, recuperación, estela, retroceso, sonido e invulnerabilidad breve al recibir daño.
- Ruta horizontal de tres distritos, Local 24, cruce y oficina roja de entrega.
- Oleadas finitas de 3, 5 y 6 enemigos; un resistente en la última. Total: 14.
- Paquete interactivo, objetivo y distancia, marcador visible, botiquines de un solo uso con recogida automática al pasar (solo si falta salud), compartida por todos los niveles.
- Cuerpos persistentes, lluvia, neón, faroles, autos, basura, señales, vitrinas y vegetación.
- Guardado automático al terminar el diálogo inicial y al despejar cada oleada.
- Final con eliminaciones, daño recibido y tiempo; reintento y menú.
- Nivel 2: distrito de carga, pistola desde el inicio, munición automática, paquete en ubicación variable y cinco oleadas (39 enemigos, 15 resistentes).
- Nueva partida permite elegir nivel; al completar el Nivel 1 aparece Continuar al Nivel 2.
- No se han implementado controles táctiles.

## Guardado

Continuar carga el último punto seguro, no una instantánea de una pelea a medias.
La partida se almacena en la carpeta de usuario de Godot: app_userdata/The Last Route/route_checkpoint.json.
Nueva partida reemplaza el punto seguro al terminar el diálogo de apertura.
Los tests usan archivos diferentes; no sobrescriben el guardado de la partida normal.

## Renderizado y arte

Resolución interna 576×324, ventana inicial 1152×648, escalado entero y texturas Nearest.
El fondo del menú usa filtrado lineal dentro de su tratamiento cinematográfico; el mundo usa Nearest.
Los assets aprobados se conservan como PNG originales y se recortan mediante AtlasTexture.
No hay personajes, objetos ni edificios dibujados con primitivas ni con _draw().
Los cuadros se muestran aproximadamente a 62×62 píxeles mediante AnimatedSprite2D; no se afirma que los PNG originales sean hojas nativas de 64×64.
La orientación noroeste de Nico utiliza la fila noreste reflejada para corregir el ángulo de la propuesta aprobada. Esto refleja también el cuchillo: es una limitación visual pendiente de un repintado específico.
Los ciclos y algunos módulos conservan las variaciones de los originales generados; el atlas y la escala no equivalen a una nueva animación dibujada a mano.

## Duración y pruebas

Actualización de movimiento: velocidad aumentada de 38 a 84 px/s a petición del usuario. Reposo fijo y caminata alineada para eliminar el vaivén. La medición de duración siguiente corresponde a la versión anterior de 38 px/s; ya no describe la duración actual, que será menor.

movement_checks.gd: 19 comprobaciones aprobadas de reposo, pivote de caminata, desplazamiento real, parada y velocidad diagonal.

Corrección de transición: reposo y caminata comparten el cuadro inicial y la cámara ya no arrastra al personaje hacia delante al arrancar. transition_checks.gd comprueba la posición en pantalla y la pose inicial en ocho direcciones.

El recorrido automático acelerado, sin teletransportes ni daño forzado, completó 14 bajas y la entrega en **447,16 segundos (7:27)** de tiempo de juego, saltando el diálogo y sin daño recibido.
Esto es una referencia de recorrido óptimo, no una prueba de primera partida humana. El objetivo de 8–12 minutos requiere tu prueba jugable.

- ui_smoke.gd: apertura de menú y ciclo de diálogo.
- playthrough.gd: 25 comprobaciones de bloqueo, movimiento, recogida, combate, pausa, guardado, tres oleadas, botiquín, entrega, derrota y reintento.
- combat_checks.gd: 7 comprobaciones de ataque real enemigo, estadísticas, alcance, muerte/cadáver, conteo único, ausencia de respawn y guardados inválidos.
- route_walk.gd: recorrido de extremo a extremo usando controles, colisiones y daño real. Se acelera el tiempo para la prueba.
- Capturas reales del renderizador en docs/screenshots. El tiempo de la pantalla de resultados de la prueba de integración es corto porque esa prueba salta posiciones para comprobar estados.

Comandos (desde la carpeta del proyecto, reemplaza Godot por tu ejecutable):

	Godot --headless --path . --editor --import
	Godot --headless --path . --script res://tests/ui_smoke.gd
	Godot --headless --path . --script res://tests/playthrough.gd
	Godot --headless --path . --script res://tests/combat_checks.gd
	Godot --headless --path . --script res://tests/route_walk.gd

## Sistemas

Ver docs/SISTEMAS.md para responsabilidades, estados, parámetros y límites de esta entrega.
Los sonidos son WAV temporales sintetizados; pueden reemplazarse conservando nombres o cambiando audio.gd.
El siguiente paso es tu revisión del Nivel 1 y las correcciones que resulten de jugarlo. No avanzar al Nivel 2 sin aprobación.

Guía del Nivel 2 y verificación: [docs/NIVEL_2.md](docs/NIVEL_2.md).
