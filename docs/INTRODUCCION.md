# Introducción de Nico

Se muestra al seleccionar Nueva partida > Nivel 1. Continuar, Reintentar y los otros niveles entran directamente al juego.

E / Enter o el botón Continuar avanzan. Escape o Saltar intro terminan la secuencia. Los textos permanecen hasta que el jugador avanza, sin límite de lectura. Las transiciones atenúan la imagen sin desplazar ni escalar los píxeles. La lluvia ambiental existente acompaña las escenas.

## Edición
- Textos y orden: assets/ui/intro/story.json. Mantener las claves image, name y text y la sintaxis JSON.
- Ilustraciones aprobadas: assets/ui/intro/01_habitacion.png, 02_telefono.png, 03_salida.png.
- Presentación e interacción: scripts/intro.gd.
- Entrada al nivel: scripts/main.gd, start_intro().

Las imágenes originales se muestran con filtro Nearest en el viewport interno de 576×324 y el proyecto escala a 1152×648. Los mensajes completos se leen en un panel inferior; el teléfono muestra un aviso corto editable. La secuencia no crea actores ni avanza el tiempo de ruta. Al terminar, el nivel 1 conserva su diálogo inicial y bloqueo de controles habitual.

## Verificación
tests/intro_checks.gd comprueba los seis textos, espacio de lectura, avance con E, salto con Escape, diálogo inicial, reintento, continuación de checkpoint y entrada directa a niveles 2–4. Usa un archivo de guardado de prueba independiente y lo elimina al terminar. Las capturas intro_00.png a intro_05.png muestran el resultado a resolución interna.
