# Nivel 8: bloqueo del Jefe y entrega de pruebas

## Historia y recorrido
- Nivel 7: la llamada llega, pero la transferencia de archivos falla. Nico conserva las pruebas.
- Nivel 8: los cuatro supervivientes caminan por el paso protegido y continúan hasta el bloqueo del Jefe y dos guardias de Vértice.
- La conversación exige entregar la memoria y los documentos; el Anclado interrumpe el enfrentamiento.
- Se eliminaron la puerta lateral, la palanca y la misión de rescatar al Jefe.
- Los civiles, el Jefe y los guardias se desplazan en pantalla durante la huida. El combate empieza al terminar la escena.
- El embarque espera a los cuatro civiles. Nico entrega las pruebas al rescate; el epílogo confirma la custodia del Jefe.

## Implementación
`harbor_level.gd`: etapas 10 (acompañar), 11 (bloqueo), 12 (fuga), 13 (combate) y 14 (embarque). Guarda las posiciones de los personajes. Los checkpoints antiguos de rescate se convierten al nuevo encuentro.
`chief_saved` y `files_sent` conservan sus nombres solo por compatibilidad con el formato de guardado. En esta revisión representan el bloqueo roto y el intento de transmisión/contacto por radio, respectivamente.
`corporate_guard_art.gd`: sprites reales con idle y cinco cuadros de caminar por guardia, atlas transparente y anclaje común de pies.
Diálogos editables: assets/broadcast/story.json, assets/harbor/story.json y assets/harbor/ending/story.json.

## Verificación
Pruebas funcionales de nivel 7, progresión completa de nivel 8, apertura por disparo, suministros, desplazamiento continuo de civiles, bloqueo, huida, combate, embarque y migración de checkpoints. Capturas revisadas de la confrontación y del combate.

## Diseños
Herramienta usada: image_gen integrada. Archivos: assets/harbor/corporate_guards.png, corporate_guards.json y breach.png.
Prompt guardias: Production sprite sheet for The Last Route, pixel art dark urban survival, transparent background. Reference image style and character scale only. TWO corporate security guards of Vertice, clearly distinct from blue reflective rescue workers. Dark charcoal tactical uniforms with muted orange shoulder patches, no readable words. Guard A stocky dark beard, Guard B slender short hair woman. BOTH adult imposing armed security, rifles held low no firing. Precisely 6 columns by 2 rows of separate full-body sprites evenly spaced in identical cells. TOP ROW GUARD A: cell1 idle facing LEFT blocking a passage, cells2-6 five sequential walking frames facing RIGHT fleeing. BOTTOM ROW GUARD B: cell1 idle facing LEFT, cells2-6 five sequential walking frames facing RIGHT fleeing. Same outfit scale proportions per guard, fixed ground baseline within every cell, completely separated silhouettes, no clipping or overlapping, generous empty margins. Crisp pixel clusters and dark outlines, no glow, no scenery or ground shadows, no text. Match 3/4 overhead game camera, not photo.
Prompt fuga: Edit this existing pixel-art cinematic for The Last Route. Preserve monster design, pose, smashed container, broken gangway, harbor ships, night colors, lights, camera and composition exactly. ONLY change far right area: remove the man with glasses in the booth and remove the enclosed booth/doorway that holds him. Replace that small area with open harbor pavement and normal industrial fence continuing the surrounding fence, so nobody appears trapped. No new people. Monster dominates scene as original. Keep crisp pixel-art style, same widescreen composition.
