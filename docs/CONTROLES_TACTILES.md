# Controles táctiles · Integración

## Uso

En dispositivos móviles o con pantalla táctil se activan automáticamente. En PC, T activa/desactiva la vista táctil y permite probarla con el ratón; también puede iniciarse Godot con `-- --touch`. Un ratón solo simula un dedo; las pruebas automatizadas envían dedos independientes para comprobar movimiento y ataque simultáneos.

- Joystick: arrastrar para moverse, con zona muerta y desplazamiento limitado.
- Ataque: mantener para repetir el ataque respetando la cadencia de cada arma. El icono cambia entre cuchillo, pistola y escopeta. Conserva la asistencia de apuntado ya existente del juego.
- Cargador: recargar una vez por toque; gris si no se necesita o no hay munición de reserva.
- Flechas: cambiar de arma una vez por toque.
- Mano: aparece cerca de una interacción disponible.
- Pausa y documentos: botones superiores. Documentos aparece en los niveles que ya ofrecen consulta de documentos/instrucciones.
- Diálogo: tocar la caja muestra la frase completa; otro toque avanza. Los controles de combate se ocultan.
- Escenas ilustradas: tocar el texto o Continuar; Saltar escena queda disponible.
- Menús, pausa y resultados: botones más altos en móvil. La lista de rutas, disponible solo tras completar los ocho niveles, permite arrastrar sin seleccionar accidentalmente una ruta.

## Archivos y responsabilidades

- `scripts/touch_controls.gd`: iconos del atlas, zonas táctiles, propiedad de cada dedo, joystick, acciones y reajuste al área segura. Limpia las pulsaciones al cambiar de contexto, cancelar un toque, pausar o perder el foco. Pausa al pasar la aplicación a segundo plano.
- `scripts/touch_route_list.gd`: desplazamiento de rutas con cancelación del botón al arrastrar.
- `scripts/controls.gd`: entrada virtual compartida. Evita que los clics emulados por toques activen el disparo de escritorio.
- `scripts/player.gd` y `shotgun_player.gd`: en modo táctil no apuntan hacia la posición del ratón emulado. Conservan su asistencia de apuntado.
- `scripts/ui.gd`: HUD móvil, textos sin teclas, botones de menú/pausa/resultados y selector desplazable.
- `scripts/main.gd`: activación automática, T, ciclo de vida y botón Atrás de Android durante la partida.
- `scripts/intro.gd`: navegación táctil de prólogo, transiciones y final.
- `project.godot`: orientación horizontal y emulación de ratón desde toque para controles nativos. En móvil se permite escala fraccionaria manteniendo filtro Nearest; el mundo conserva 576 × 324 y la UI respeta el área segura.

## Assets finales

`assets/ui/touch/controls_atlas.png`: PNG RGBA transparente, 1774 × 887. Veinticuatro botones (ocho iconos por tres estados) y dos piezas de joystick. Las regiones se seleccionan con AtlasTexture, sin dibujar iconos mediante nodos. Se usa un único atlas para mantener el estilo y evitar duplicados.

Tamaños lógicos: joystick 88, palanca 32, ataque 64, secundarios 44, interacción 48 e iconos superiores 32 píxeles. Las zonas de acción son de al menos 48 × 48 unidades lógicas, aunque el dibujo sea menor. El mínimo físico en dp deberá validarse con la densidad y área útil del dispositivo de destino.

Generación: herramienta integrada de imágenes, a partir de la hoja aprobada. Prompt completo en `assets/ui/touch/production_prompt.json`. No se reutiliza la hoja de presentación como fondo del juego.

## Comprobación

- `tests/touch_checks.gd`: entrada táctil en los ocho niveles, iconos/transparencia, dos dedos simultáneos, soltado/cancelación, recarga, cambio de arma, pausa, pérdida de foco, diálogos/documentos, área segura simulada y vuelta a escritorio. Resultado: TOUCH FAILURES: 0.
- `tests/touch_ui_checks.gd`: eventos de toque por Input.parse_input_event para nueva historia, escenas, pausa, ayuda, reintento y lista desplazable. Resultado: TOUCH UI FAILURES: 0.
- Pruebas previas del menú, armas y final del nivel 8 conservan sus comprobaciones sin fallos.
- Capturas renderizadas revisadas: `docs/screenshots/touch_01_gameplay.png`, `touch_02_pause.png`, `touch_03_dialogue.png`, `touch_04_document.png`.

Las comprobaciones se ejecutaron en Godot sobre Windows, incluyendo eventos táctiles simulados. No se ha exportado un APK ni se ha probado en Android/iOS físico. Quedan por validar ergonomía con dos pulgares, densidad de pantalla, recortes de cámara, gestos del sistema y rendimiento real. Algunas pruebas headless del proyecto muestran avisos de recursos retenidos al cerrar; no representan fallos en las comprobaciones funcionales enumeradas.

Referencia de API para el área segura: https://docs.godotengine.org/en/4.6/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area

Corrección del atajo: F8 está reservado por Godot para detener la ejecución. Ahora se utiliza T o Pausa → Controles → Mostrar/Ocultar controles táctiles. Prueba: tests/touch_shortcut_checks.gd.
