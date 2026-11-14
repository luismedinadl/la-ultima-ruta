# Nivel 5 · Rescate en el canal

Integrado después del campamento. Seleccionable desde el menú y desde el resultado del nivel 4.

## Recorrido

1. Llegar al taller y despejar seis infectados. Hablar con Mara.
2. Avanzar a las bombas: ocho enemigos, cuatro inicialmente distraídos. Los disparos los alertan.
3. Encender el generador. La compuerta necesita 32 segundos y eliminar dos grupos finitos de cinco y cuatro enemigos.
4. Defender la misma calle mientras el grupo avanza por su costado, detrás de una barrera física de concreto. La cuarta oleada tiene nueve enemigos. A los 22 segundos o al despejarla llega una quinta oleada de seis enemigos (dos resistentes). El recorrido requiere 55 segundos y eliminar ambas oleadas.
5. Reunirse con Mara. El código de los paquetes señala el centro de distribución para la siguiente parte de la historia.

Total: 38 enemigos, incluidos dos perros. Mara y tres civiles avanzan por la franja lateral de la misma calle que Nico; no tienen una barra de vida individual. La defensa consiste en combatir las dos oleadas mientras el grupo avanza.

## Sistemas y archivos

- `scripts/rescue_level.gd`: objetivos, encuentros, civiles, generador, recogidas y puntos seguros de guardado.
- `scripts/rescue_art.gd`: recortes de atlas, seis cuadros de caminata por civil, poses de reposo y retratos.
- `assets/rescue/dialogues.json`: todos los nuevos diálogos, editables como texto en español.
- `assets/rescue/regions.json`: recortes y puntos de apoyo estables; las imágenes originales no se alteran.
- `scenes/level_05.tscn`: entrada al nivel.
- `main.gd`, `ui.gd`, `save_game.gd`: menú, paso al nivel siguiente, retratos y validación de guardados.

El jugador conserva el acceso a cuchillo, pistola y escopeta. La reserva de pistola está limitada a 36; las cajas dan 12 balas. Los cartuchos y botiquines se recogen al pasar. Los recursos iniciales se reinician por nivel, igual que en las rutas anteriores.

Los fondos propios son taller, estación de bombas y calle de servicio; se eliminó el puente del fondo. El portón y los controles tienen estados apagado/cerrado y encendido/abierto. La apertura se representa con progreso y cambio de estado, sin una animación mecánica continua.

## Verificación

`tests/rescue_checks.gd`: progresión completa, 38 bajas y dos perros, conversaciones, guardados seguros, pausa durante diálogos, barrera física para Nico y todos los enemigos y pantalla final. Usa bajas controladas para comprobar la secuencia.

`tests/rescue_combat_checks.gd`: movimiento y persecución con física activa, impactos de pistola, dispersión de escopeta, cuchillo sincronizado y recogidas automáticas.

`tests/connections_checks.gd`: regresión narrativa de niveles anteriores; comprobaciones aprobadas, con advertencia de recursos al cerrar ese comprobador.

Las pruebas emplean archivos de guardado separados de la partida del usuario. La duración y dificultad finales requieren una partida humana; no se ha medido una sesión de 10–12 minutos.
