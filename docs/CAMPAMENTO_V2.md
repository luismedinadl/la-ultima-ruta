# Nivel 4 · Campamento de contención aprobado

Se sustituyeron todas las fachadas urbanas del Nivel 4 por fondos propios basados en los tres diseños aprobados.

## Arte final

- `assets/containment/backgrounds/medical.png`: acceso, ambulancia y refugios sanitarios.
- `assets/containment/backgrounds/isolation.png`: clasificación, refugio de documentos y jaulas bajo lonas.
- `assets/containment/backgrounds/perimeter.png`: cerco final con una abertura reservada para la puerta interactiva.

Los tres PNG conservan sus originales de 1672 × 941. Se presentan en secciones de 576 × 324, con filtro Nearest y una unión discreta entre bordes. Los refugios y equipos posteriores comparten suelo, iluminación y perspectiva dentro de cada fondo. No se superponen tiendas adicionales a fachadas ni se duplican las ambulancias, jaulas o faroles ya presentes en el arte. El suelo recibe una reducción de contraste y saturación para conservar la lectura de personajes y recursos.

La puerta mantiene sus estados cerrado y abierto como sprites independientes, a una escala común y dentro de la abertura del cerco. Documentos, armas, suministros y barreras de los pasos alternativos siguen siendo objetos separados. Los refugios y equipos del fondo quedan fuera del corredor transitable; las barreras centrales conservan sus colisiones.

## Verificación

- Revisión de las capturas de Godot en acceso, documentos, encuentro final y salida abierta.
- Pruebas funcionales de los cinco encuentros, documentos, escopeta, guardado y salida: sin fallos.
- Recorrido automatizado con movimiento y combate reales: cinco encuentros, 39 enemigos eliminados y llegada al final.
- Los niveles 1–3 no reciben cambios de escenario.

Las imágenes se generaron con la herramienta integrada imagegen. Los prompts finales están en `PROMPTS_FONDOS_CAMPAMENTO.json`. Las vistas del juego actualizado están en `screenshots/19_containment.png`, `20_readable_document.png`, `21_shotgun_hollow.png` y `23_emergency_exit.png`.
