# Ambiente del nivel 3
Fuente preservada: assets/audio/leberchsuspense.mp3 (4.609.253 bytes).
Archivo de reproducción: assets/audio/leberchsuspense_loop.ogg (1.777.798 bytes).
Duración: 133 segundos, estéreo a 44.100 Hz.
Se usa el tramo de 2 a 138 segundos del original, evitando entrada atenuada y salida con fundido/silencio. Solapamiento cíclico de 3 segundos con curvas seno/coseno. La copia se exportó a Vorbis; el original no se modifica.
Godot usa loop nativo. El fondo genérico drone se pausa en el nivel 3 y se restaura al salir. Los demás niveles conservan rain.wav. El antiguo metro_ambience.wav se retiró del proyecto y tiene copia de respaldo en el workspace, work/metro-audio.
Validación: análisis del OGG decodificado sin silencios mayores a 150 ms por debajo de -50 dB, pico -3,1 dBFS; tests/metro_audio_checks.gd verifica selección de los ocho niveles, cruce del fin de pista y retorno al menú. No se realizó una evaluación auditiva humana.

## Actualización: los ocho niveles
leberchsuspense_loop.ogg se reproduce ahora en el reproductor music en los niveles 1–8, a -15 dB y con bucle nativo. ambience conserva la lluvia y sus cambios de volumen en interiores; se pausa en el metro. El menú y la introducción usan el ambiente anterior (lluvia y drone), identificado por set_route_ambience(0). La prueba metro_audio_checks.gd fue actualizada para cubrir las ocho selecciones, independencia de la lluvia, repetición y retorno al menú.
