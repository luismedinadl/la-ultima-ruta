# Nivel 8 · La última ruta
Implementación del final de The Last Route en Godot 4.

## Cómo jugar
Desde Nueva partida, elige «Nivel 8 · La última ruta», o termina el nivel 7 y pulsa Continuar.
WASD/flechas: movimiento. Espacio/clic: ataque. Q: arma. R: recarga. E/Enter: interacción/diálogo. Escape: pausa. Tab: documento.
Las cajas y botiquines se recogen al pasar, si hacen falta. Pistola: cajas de 12, reserva máxima 36. Escopeta: cajas de 4, reserva máxima 12.
Antes de El Anclado hay un punto seguro. Tras una derrota, «Reanudar desde el punto seguro» conserva lo guardado; «Reintentar» reinicia el nivel.

## Recorrido y combates
Acceso: 7 enemigos. Patio: 8. Control de la reja: 13. Cruce de civiles: 13.
Son 41 enemigos en los encuentros, incluidos 3 perros; no se reducen los grupos al añadirlos.
El Anclado puede llamar a dos grupos de 3 Huecos, una sola vez cada uno. Total máximo: 48 bajas contando al jefe.
No hay oleada después del jefe. El tramo final permite caminar hasta Mara antes del desenlace.

## Sistemas
- harbor_level.gd: estados explícitos de recorrido, encuentros finitos, puerta principal y salida lateral independientes, franja protegida para civiles, recogida de suministros y guardado.
- anchored_enemy.gd: aproximación, anticipación, ataque y recuperación. Carga con dirección fijada; barrido frontal; golpe cercano. Cada ataque puede evitarse. Recibe más daño durante recuperación.
- Segunda fase: espera a terminar una recuperación, cambia a atlas sin armazón, acelera sus movimientos y acorta la anticipación. No cancela un ataque de forma inesperada.
- harbor_art.gd: atlas PNG, regiones medidas por transparencia, animaciones y retratos. El dibujo de los personajes no se genera mediante nodos.
- main.gd: conexión desde nivel 7, escena ilustrada de la ruptura, diálogos, secuencia final y regreso a resultados.
- save_game.gd: valida estados seguros y coherencia de reja, rescate del Jefe y derrota del enemigo final.
- ui.gd: selector de ocho niveles, reanudación y resultado final. No ofrece un nivel 9.

## Textos editables
assets/harbor/story.json contiene diálogos y la orden de embarque.
assets/harbor/ending/story.json contiene el desenlace y los créditos.
Los objetivos breves están en objective_text() de scripts/harbor_level.gd.
No modificar los nombres de claves JSON; sí los valores text/name.

## Arte final
Seis fondos portuarios originales y una escena de ruptura. Tres ilustraciones finales.
Atlas de El Anclado: 24 poses de acciones y 30 de locomoción por fase; orientaciones obtenidas mediante cinco vistas y reflejo. En la diagonal trasera de la segunda fase se usan tres poses estables para evitar un giro involuntario entre cuadros.
Atlas de 18 poses del Jefe/personal portuario; 12 objetos con estados; tres retratos del Jefe.
Personajes civiles, armas, botiquines y efectos de combate reutilizan assets reales existentes.
PNG de producción generados con imagegen integrada. Fondos se presentan a 576 × 324 con filtro Nearest. Los atlas se usan por regiones; no se recortaron personajes de las láminas conceptuales.
Los objetos que cambian —contenedor y pasarela— se retiraron del fondo de la arena y se representan como sprites independientes.

## Verificación
harbor_checks.gd: progresión completa, cuatro combates, reinforzos, documento, civiles, ambas puertas, escena de ruptura, punto previo al jefe, guardado/restauración, desenlace, créditos y textos.
harbor_combat_checks.gd: rayos reales de pistola/escopeta, alcance y esquiva de tres ataques, segunda fase, daño real de cuchillo, suministros automáticos y colisiones de reja/franja civil.
connections_checks.gd, containment_checks.gd y broadcast_checks.gd: regresiones de niveles anteriores.
Se revisaron capturas reales del juego. Las pruebas de daño no sustituyen una partida humana para valorar la dificultad y el ritmo final.

