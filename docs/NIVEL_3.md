# Nivel 3 — Bajo la ciudad

## Acceso

Nueva partida → Nivel 3 · Bajo la ciudad. También se puede continuar desde los resultados del Nivel 2. Reintentar reinicia el nivel actual; Continuar recupera el último punto seguro.

## Recorrido

Acceso y vestíbulo → batería de mantenimiento → andén → control → salida. Cuatro encuentros principales y dos grupos distraídos, con 33 enemigos en total: 22 básicos, 8 resistentes y 3 perros infectados. No hay spawns infinitos. Las distancias principales mantienen aproximadamente 50 m; la salida está a 25 m del panel.

Los grupos pequeños contienen dos enemigos cada uno. El vestíbulo incorpora cinco; mantenimiento seis; el andén siete; la defensa final ocho en tres entradas de 2, 3 y 3. Además se añade un perro en mantenimiento, otro en el andén y uno en la última entrada de defensa; no sustituyen a ningún zombi. El arranque del panel necesita 30 segundos de progreso efectivo y la eliminación de todos los defensores. Un enemigo a menos de 46 píxeles del panel interrumpe el arranque; despejar la zona reanuda lo acumulado. La pausa y el diálogo detienen la simulación.

## Vista y ruido

Los zombis distraídos permanecen en reposo hasta detectar a Nico. La visión abarca 155 píxeles en la dirección que miran, exige línea libre y tarda 0,2 segundos en confirmar al jugador. A menos de 42 píxeles pueden detectarlo desde cualquier lado, respetando obstáculos. No hay invisibilidad por quedarse quieto.

El cuchillo se oye a 80 píxeles y provoca investigación durante 3 segundos; el enemigo herido entra en persecución. El disparo alerta a 360 píxeles. Los obstáculos reducen el alcance audible al 55 %. Solo reaccionan enemigos ya existentes; nunca aparece un enemigo nuevo por ruido. Una vez alertado, dejar de disparar no cancela la persecución. Los encuentros principales activan sus grupos de forma explícita.

Los signos de interrogación y exclamación aparecen solo en los grupos inicialmente distraídos que reaccionan al ruido; los enemigos propios de las oleadas no los muestran. Los disparos producen ruido para la IA, pero no dibujan círculos en pantalla. La visibilidad y el ruido no cambian las reglas de los niveles 1 y 2.

## Controles y recursos

- WASD / flechas: movimiento.
- Espacio: ataque con asistencia; clic izquierdo: disparar hacia el cursor.
- R: recarga; Q: pistola/cuchillo.
- E / Enter: batería, panel, salida y diálogos.
- Escape: pausa.
- Reserva inicial y máxima de 36, cargador de 12.
- Seis cajas de 12, desde después del primer objetivo; recogida automática.
- Cinco botiquines de +35; recogida automática si falta salud, sin superar 100.

El guardado conserva batería, suministros, salud, munición y supervivientes del encuentro pequeño. Solo se guarda en fases seguras (0, 2, 4, 6, 8); perder durante la defensa vuelve al punto previo a instalar la batería. No se modifica el guardado personal al ejecutar las pruebas: utilizan rutas user:// propias.

## Arte y sonido

Los módulos provienen de la lámina aprobada y se leen mediante rectángulos individuales: se excluyen título, separaciones y elementos vecinos. Los nuevos atlas de objetos e indicadores tienen sus propios recortes. El suelo final es una textura uniforme nueva con contraste bajo, sin los parches rectangulares de reflejos de la primera prueba.

Archivos fuente y recortes: assets/metro/modules.png, props.png, signals.png, floor.png y regions.json. Los PNG originales no se alteran; Godot usa AtlasTexture, Nearest y un umbral de transparencia en objetos e indicadores. No se dibujan personajes, edificios ni objetos con código.

Escalas de juego: paredes 178 × 196, batería 28 × 36, terminal 40 × 60, banco 74 × 48, torniquete 42 × 44, gabinete 38 × 62, alertas hasta 12 × 16. Las alertas tienen cuatro cuadros; el terminal usa cuatro estados. La puerta utiliza las imágenes cerrada/abierta y una transición de retracción de 0,8 segundos. No se presenta esa transición como una animación dibujada de seis cuadros. Nico y ambos zombis humanos conservan sus sprites actuales. El perro infectado utiliza tres nuevos atlas, con carrera y mordida de seis cuadros, daño y muerte de tres, y ocho orientaciones (cinco dibujadas y tres reflejadas).

El ambiente del metro sustituye la lluvia exterior por un WAV temporal de zumbido eléctrico y gotas. Se conservan los sonidos funcionales de combate. Las fuentes y prompts figuran en ARTE_NIVEL_3.txt.

## Sistemas

- metro_level.gd: escenario, objetivos, encuentros finitos, batería, defensa, guardado y ruido.
- metro_enemy.gd: percepción y estados distraído/investigación/persecución; reutiliza combate, animación y colisiones del enemigo común.
- metro_art.gd: acceso a atlas y diálogo inicial.
- main.gd / ui.gd: selección, transición entre niveles, cierre narrativo y resultados.
- enemy.gd: método movement_target reutilizable; permite a algunos enemigos acercarse al panel cuando Nico está lejos.
- audio.gd: selección de ambiente por nivel.

## Verificación

metro_checks.gd cubre detección, obstáculos, ruido, persistencia de alerta, batería, guardado, defensa/interrupción/reanudación, pausa, salida, resultados y reintento. metro_walk.gd recorre la estación mediante movimiento, combate y suministros reales, sin teletransportar ni eliminar enemigos por comandos: 33 bajas y salida completada, con reserva final de 0. Su recorrido de 115,3 segundos de simulación es una prueba automatizada, no una estimación de duración para una primera partida humana.

También se comprobaron los recorridos funcionales de los niveles 1 y 2, las armas y los botiquines en los tres niveles. Capturas reales en docs/screenshots/15_metro_dialogue.png y 16_metro_0.png a 16_metro_3.png. El equilibrio y la sensación de dificultad aún pueden ajustarse tras la prueba humana.

## Perro infectado

Desde el Nivel 3 aparecen tres, de uno en uno. Velocidad de 113,28 píxeles/s: el doble de su velocidad anterior (56,64) y cuatro veces los 28,32 del zombi básico. Es ligeramente más rápido que Nico (105). Salud 110; mordida de 24 puntos, anticipación de 0,28 s y separación mínima de 1,25 s entre ataques. Alejarse del alcance durante la anticipación evita el daño. Emite un gruñido al entrar y deja un cuerpo no bloqueante al morir. Comparte percepción y navegación con los infectados del metro.

`infected_dog.gd` y `dog_art.gd` son reutilizables para futuras rutas. `dog_checks.gd` comprueba velocidad física, daño, esquiva, recuperación, guardado, cadáver y los 192 cuadros/orientaciones disponibles. Los estados de daño y muerte usan 3 cuadros por dirección; el reposo mantiene quieta la primera pose. Fuentes y prompts en `ARTE_PERRO_INFECTADO.txt`. Para ver las tres apariciones, inicia una partida nueva del Nivel 3: continuar un punto seguro anterior no repite encuentros ya superados.
