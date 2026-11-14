# Radio al comenzar el nivel 5

Dos ilustraciones muestran a Nico encontrando una radio sobre una caja y encendiéndola. Texto editable en `assets/ui/radio/story.json`:

- Nico: «Una radio. A ver si todavía funciona.»
- Nico: «Sí, funciona. Se escucha algo…»

Después comienza el diálogo existente de Mara. E / Enter o el botón Continuar avanzan; Escape salta las ilustraciones y lleva a la llamada de Mara. Durante la escena, movimiento, combate y tiempo de ruta permanecen bloqueados. Continuar un punto seguro no repite la escena. Reiniciar el nivel sí la muestra.

Se reutiliza el visor de escenas ilustradas `intro.gd`, con sus transiciones. La conexión está en `main.gd`, función `show_radio_scene`. Las ilustraciones son imágenes reales, con filtro Nearest.

Prueba: `tests/radio_checks.gd` comprueba secuencia, legibilidad, bloqueo, salto y continuación sin repetición.
