# Supervivencia

Disponible al completar los ocho niveles de la campaña. El botón y la entrada al modo comprueban el desbloqueo. Esta partida no guarda ni modifica puntos seguros de la historia.

## Reglas

- Nico empieza con cuchillo, pistola y escopeta: pistola 12/24 y escopeta 4/8.
- Oleada normal N: N + 1 enemigos. La primera tiene dos; la 11 tiene doce.
- Básicos (con sus variantes visuales), resistentes, perros y Huecos se seleccionan al azar desde la primera oleada, con igual probabilidad por tipo. No es obligatorio que todos aparezcan en una oleada corta.
- Las oleadas 10, 20, 30… contienen solo un Anclado. No hay refuerzos alrededor del jefe.
- Las oleadas 1–5 colocan una caja de 12 balas y una de 4 cartuchos; las 6–10, dos de cada arma; las 11–15, tres, y así sucesivamente. Cada cinco oleadas se añade una caja de cada arma. El Anclado recibe como mínimo dos de cada arma. Las cajas se distribuyen por el suelo transitable y se recogen por contacto, conservando los límites actuales de munición. En partidas muy largas se acumulan cajas adicionales en los mismos puntos, disponibles cuando haya espacio en la reserva.
- No hay botiquines ni recuperación de salud, incluidas las oleadas del Anclado. El daño se conserva durante toda la partida.
- Hay seis segundos para recoger suministros antes de que entren enemigos. Los suministros sobrantes se renuevan al comenzar la siguiente oleada.
- Hasta 24 enemigos vivos simultáneamente. Los restantes entran progresivamente: no se recorta el total de la oleada. Se conservan como máximo 12 cadáveres durante combates largos.

## Escenarios

Cinco oleadas consecutivas por escenario: ciudad comercial, distrito de carga, metro, campamento, canal, distribución, radio y puerto. En la oleada 41 vuelve la ciudad. Se utilizan los assets existentes sin personajes, objetivos ni objetos narrativos. El cambio usa un fundido breve; se realiza con la zona despejada, conservando salud y munición. Se pausa también al pausar el juego.

## Sistemas

`survival_level.gd` controla las fases de suministros, combate y transición; reutiliza movimiento, armas, enemigos, efectos y controles de la campaña. Las arenas están despejadas y limitadas para impedir que queden enemigos fuera del recorrido. El Anclado conserva sus señales y fases de ataque.

`main.gd` abre el modo, conecta el HUD y muestra resultados independientes al morir. Reintentar comienza otra supervivencia desde la oleada 1. `ui.gd` habilita el botón y muestra oleadas superadas, eliminaciones y tiempo. Los controles táctiles muestran movimiento, ataque, cambio de arma, recarga y pausa, sin documentos ni interacción.

## Validación

Prueba de 41 oleadas: cantidades, todos los tipos, jefes aislados, los ocho escenarios, vuelta al primero, suministros, pausa, resultados, reintento, desbloqueo y aislamiento del guardado de campaña. Prueba adicional de persecución real, cola de enemigos y ataques del Anclado. Capturas de los ocho escenarios en docs/screenshots/survival_*.png.

La duración y dificultad se deberán afinar con partidas reales en PC y Android. Esta implementación no actualiza la APK anterior.
