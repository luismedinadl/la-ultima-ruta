# Conexiones de los niveles 2–4

## Textos editables
- assets/ui/connections/dialogues.json: conversación inicial del nivel 2, final del 2, inicio y final del metro y ambas variantes del final del campamento.
- assets/ui/connections/story.json: las dos frases sobre la ilustración de recogida de la pistola.

Usar palabras comunes, frases cortas y una idea por cuadro en todos los textos: diálogos, objetivos, notas y descripciones. No revelar notas que Nico no haya leído.

## Funcionamiento
El nivel 2 inicia bloqueado con la conversación del depósito. Al cerrarla, main.gd muestra las dos páginas ilustradas usando intro.gd, ahora configurable por carpeta. La secuencia mantiene bloqueados actores y tiempo. E/Enter avanza y Escape la omite. Al terminar se libera el nivel y se guarda el checkpoint normal. La pistola y munición iniciales se conservan; la escena no concede unidades adicionales. Continuar un checkpoint no repite la escena.

route_story.gd carga los textos y elige el final del campamento según document_read.has(1). Sin la nota opcional, Nico solo acusa al Jefe de ocultar el contenido de los paquetes. Con ella, también denuncia la falsa evacuación.

Los letreros son sprites de las imágenes aprobadas, con regiones basadas en transparencia y filtro Nearest. Se colocan en las paredes: recepción y acceso al metro al final del nivel 2, acceso al campamento en la estación y corredor de servicio sobre la valla junto a la salida del campamento. No añaden obstáculos ni cambian oleadas.

## Verificación
connections_checks.gd prueba bloqueo de movimiento y reloj, lectura, finalización y salto de la escena, conservación de munición, continuación, transición al metro, ambas ramas de documentos y ajuste del texto en el panel. Se revisaron capturas a 576×324. intro_checks.gd sigue pasando para el prólogo del nivel 1.
