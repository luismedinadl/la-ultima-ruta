# Nivel 2 — Distrito de carga

## Cómo jugar

En el menú, abre **Nueva partida → Nivel 2 · Distrito de carga**. También puedes continuar al Nivel 2 desde la pantalla de entrega completada del Nivel 1. **Continuar** recupera el nivel y el último punto seguro guardado. **Reintentar** reinicia el nivel actual.

- WASD / flechas: movimiento.
- Espacio: disparar con asistencia hacia el enemigo visible más cercano; con el cuchillo equipado, ataque cuerpo a cuerpo.
- Clic izquierdo: disparar hacia el cursor.
- R: recargar.
- Q: cambiar entre pistola y cuchillo, con transición de equipo.
- E / Enter: recoger o entregar el paquete y avanzar diálogos.
- Escape: pausa.
- Botiquines: recogida automática al pasar, en ambos niveles y futuras rutas; curan 35 puntos y permanecen si la salud está completa.
- Munición: se recoge al pasar sobre una caja, sin pulsar E.

## Qué contiene

Pistola disponible desde el diálogo inicial. Nico se resiste a continuar y el Jefe lo convence prometiendo un lugar en el puesto de evacuación. El arma se llama únicamente «Pistola»; no aparece marca ni calibre.

El paquete aparece en uno de tres puntos accesibles del primer sector. La selección se conserva al guardar y continuar. No se recoge en el Local 24. El marcador señala la ubicación elegida.

Cinco oleadas: **5, 7, 8, 9 y 10 zombis**, 39 en total. Incluyen **1, 2, 3, 4 y 5 resistentes**, respectivamente. Los enemigos del segundo nivel tienen un multiplicador de 1,18 en salud y velocidad. Las oleadas son finitas y se activan por objetivos y zonas. Tras la quinta, se abre la entrega en el puesto de evacuación.

Almacenes, depósito, oficina de carga y puesto de evacuación usan un nuevo atlas industrial. Se conserva el asfalto sobrio y los reflejos moderados aprobados. Los objetivos intermedios están separados aproximadamente por 50 m; el primer trayecto varía ligeramente con el paquete aleatorio.

## Arma y suministros

Cargador de 12, reserva inicial de 36 y máximo de reserva de 36. Hay 10 cajas distribuidas desde después del primer objetivo hasta el sector final (antes 15), sin cajas en el trayecto inicial, conservando sus identificadores para los guardados anteriores. Todas las cajas aportan 12, hasta completar la capacidad. Si la reserva está llena, la caja permanece. Cada caja solo se recoge una vez; su estado se guarda. Los guardados anteriores se ajustan al límite de 36 al cargarlos. Las cajas grandes de 24 quedan desactivadas.

Cada impacto de pistola causa 44 puntos de daño. La consulta física se detiene en el primer enemigo u obstáculo: no atraviesa autos. Cadencia máxima aproximada de un disparo cada 0,26 segundos; recarga de 1,2 segundos. Recargar transfiere únicamente la munición disponible. Recibir daño interrumpe la recarga sin gastar balas de reserva. Nico puede desplazarse al 65 % de su velocidad durante disparo y recarga.

Los sonidos de disparo, recarga y cargador vacío son WAV temporales funcionales, sustituibles posteriormente.

## Sistemas y archivos

- `scripts/level_two.gd`: diálogo inicial y definición de las cinco oleadas.
- `scripts/level.gd`: construcción de ambos niveles, objetivos, posiciones del paquete, suministros, disparo contra obstáculos, navegación de enemigos y datos del punto seguro.
- `scripts/player.gd`: estados de arma, disparo, recarga, daño y cambio al cuchillo.
- `scripts/art.gd` y `assets/pistol_regions.json`: recortes individuales y orientación de los sprites; cuadros alineados por la cabeza y un lienzo amplio para las caídas.
- `scripts/ui.gd`: selección de nivel, contador cargador/reserva, avisos de recarga y resultados.
- `scripts/save_game.gd`: validación y compatibilidad con los puntos seguros del Nivel 1.
- `scripts/controls.gd`: adaptador de teclado/ratón, preparado para futuros controles táctiles.

Los originales PNG se conservan. Los recortes se definen con AtlasTexture, sin dibujar personajes o edificios mediante código. Algunas orientaciones reutilizan filas reflejadas horizontalmente para mantener coherencia. El reposo usa el primer cuadro de caminar y permanece quieto. Los efectos visuales emplean sprites del atlas de equipo y las hojas existentes.

## Verificación

- Nivel 2: diálogo y bloqueo de controles; munición automática una sola vez; recarga y pausa; guardado de nivel, paquete y balas; cinco oleadas y número de resistentes; entrega final y reintento del nivel correcto.
- Armas: autos bloquean balas; impacto en línea libre; reserva llena; límite de capacidad; recarga parcial; daño que cancela recarga; cuchillo y transiciones de equipo.
- Recorrido automatizado con movimiento, colisiones, combate, botiquines y munición reales, sin teletransportar ni matar enemigos por comandos: **39 bajas y entrega completada**, 148,4 segundos de simulación. Ese tiempo es de un agente de prueba, no una estimación de duración para una primera partida humana.
- Regresión: 25 comprobaciones del Nivel 1, movimiento de Nico, transiciones, zombis, colisiones de autos y migración de distancias.

Capturas del motor en `docs/screenshots/11_level2_dialogue.png`, `12_level2_pistol.png` y `13_level2_shot.png`. El ajuste fino de dificultad sigue abierto a tu prueba del nivel.
