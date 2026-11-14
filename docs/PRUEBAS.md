# Resultado de validación

Actualización de movimiento: 19 comprobaciones aprobadas con velocidad 84 px/s, reposo fijo y caminata alineada. La medición de recorrido de 7:27 que figura abajo es histórica y corresponde a 38 px/s.

Motor: Godot 4.7.2. Windows. Compatibility / OpenGL, NVIDIA GeForce RTX 4070 Laptop GPU.

| Prueba | Resultado |
|---|---|
| Importación y compilación | Sin errores de scripts |
| Menú y diálogo | PASS |
| Integración de ruta | 25 comprobaciones, 0 fallos |
| Combate y guardado inválido | 7 comprobaciones, 0 fallos |
| Recorrido con entrada y colisiones reales | Entrega completada, 14 bajas |
| Tiempo del recorrido automático | 447,16 s (7:27); diálogos saltados |
| Revisión visual | Menú, diálogo, combate, cruce, entrega y resultados |

Se corrigieron el tamaño mínimo de TextureRect, el alto de las barras, el encuadre de las capturas, el cierre de audio y la validación de tipos del guardado.
Las últimas pruebas de menú, combate e integración finalizan sin los avisos de recursos del primer ensayo.

El recorrido automático no representa a un jugador principiante. La duración humana de 8–12 minutos, la dificultad y las preferencias visuales quedan pendientes de tu sesión de revisión.
Los sonidos son provisionales funcionales y la dirección NO de Nico utiliza reflejo del atlas; detalles en LEEME.md.

Corrección de recortes: 672 regiones individuales en 14 hojas. Vista GPU en docs/screenshots/07_sprite_crops.png. Movimiento: 19 comprobaciones; transición: 9; progreso: 25, sin fallos. Los PNG originales se conservan; AtlasTexture usa márgenes para conservar el pivote y un shader excluye los píxeles vecinos de dos cuadros de muerte solapados.
