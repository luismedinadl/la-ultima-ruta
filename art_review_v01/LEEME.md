# The Last Route — revisión visual 01

Estado: FASE 1 EN CURSO. Propuestas visuales reales en PNG; no son todavía assets finales listos para importar.
No se han creado escenas, nodos, scripts ni lógica del juego. El proyecto vacío que ya existía en Documents/GodotProjects/the-last-route no se ha modificado.
El directorio de revisión contiene .gdignore para evitar importaciones automáticas.

## Abrir la presentación
Abre index.html en un navegador. Incluye todas las familias, hojas separadas por animación, revisiones, tamaños y enlaces a los originales.
Las vistas de escenarios son ilustraciones de diseño, no capturas de un videojuego implementado.
El menú con botones es un mockup; menu_background.png contiene el fondo independiente sin texto.

## Dirección visual
Supervivencia urbana nocturna. Lluvia ligera, asfalto mojado, comercio abandonado, neón débil, suciedad y vegetación urbana.
Cámara prevista: 3/4 cenital ortográfica, recorrido de izquierda a derecha, sin perspectiva de fuga.
Nico: cabello oscuro, chamarra oscura, mochila naranja, pequeños reflectantes cian y cuchillo.
Zombi: piel gris verdosa, cabeza casi calva, ropa urbana rasgada, silueta encorvada y ojos discretamente luminosos.
Local 24 se identifica con cian; el cruce con faroles cálidos; la entrega con fachada roja y puerta cálida.

## Paleta principal propuesta
| Color | HEX | Uso |
|---|---|---|
| Azul noche | #111A2B | Ambiente y sombras |
| Gris carbón | #252832 | Ropa, asfalto y metal |
| Morado profundo | #34253F | Sombras secundarias |
| Cian tenue | #5E9B9B | Neón, objetivos y reflectantes |
| Naranja cálido | #D68A49 | Mochila y faroles |
| Rojo peligro | #A63845 | Daño y acentos de peligro |

Son colores de dirección de arte, no una paleta indexada verificada de los PNG. Se requieren rampas adicionales para piel, metal y luces.

## Especificación de animación
Todas las hojas de personajes proponen 8 filas y 6 poses por fila: 48 poses por animación.
Orden previsto de filas: S, SO, O, NO, N, NE, E, SE. Columnas: tiempo de izquierda a derecha.
La revisión detecta orientaciones que no respetan ese orden; no usarlo todavía para recortar automáticamente.
Tamaño de producción previsto: 64×64 por cuadro; hoja 384×512. No corresponde a las dimensiones actuales.

| Personaje | Archivo / acción | Cuadros por dirección | Reproducción prevista |
|---|---|---:|---|
| Nico | idle | 6 | Bucle, 6 fps |
| Nico | walk_v02 | 6 | Bucle, 10 fps |
| Nico | knife_attack | 6 | Una vez, duraciones 90/70/45/55/80/100 ms |
| Nico | hurt | 6 | Una vez, 14 fps |
| Nico | death | 6 | Una vez, 8 fps; conservar último cuadro |
| Nico | pickup_package | 6 | Una vez, 8 fps |
| Nico | delivery | 6 | Una vez, 8 fps |
| Zombi | idle | 6 | Bucle, 4 fps |
| Zombi | walk_v02 | 6 | Bucle, 6 fps |
| Zombi | attack | 6 | Una vez, 8 fps |
| Zombi | hurt | 6 | Una vez, 12 fps |
| Zombi | death | 6 | Una vez, 7 fps; conservar cuerpo |

Los tiempos son propuestas, no animaciones probadas en movimiento.
El ataque de Nico contiene preparación, anticipación, golpe, estela y recuperación.
La muerte termina con cuerpo caído. La recogida y entrega requieren corregir continuidad del paquete.
Las versiones iniciales walk se conservan para comparación; v02 es la propuesta preferida, aún sin validación final.

## Objetos: medidas de producción previstas
Los 20 elementos existen en props.png como lámina; aún no están extraídos y normalizados por separado.

| Elemento | Tamaño previsto (px) | Cuadros |
|---|---|---:|
| Paquete | 24×24 | 1 |
| Señal de objetivo física | 32×48 | 1 |
| Botiquín | 24×24 | 1 |
| Caja de munición | 32×24 | 1 |
| Basurero metálico | 32×48 | 1 |
| Bolsa de basura | 24×24 | 1 |
| Cono de tránsito | 24×32 | 1 |
| Caja de cartón | 32×32 | 1 |
| Barrera policial rota | 96×48 | 1 |
| Auto abandonado | 128×80 | 1 |
| Poste de luz | 32×128 | 1 |
| Señal de tránsito | 32×64 | 1 |
| Puerta de local | 48×80 | 1 |
| Vitrina | 96×80 | 1 |
| Charco | 64×32 | 1 |
| Mancha urbana y basura | 48×32 | 1 |
| Grafiti | 64×48 | 1 |
| Anuncio de neón | 96×48 | 1 |
| Carteles de pared | 48×64 | 1 |
| Vegetación descuidada | 48×32 | 1 |

## Tiles y arquitectura
tiles.png propone 64 muestras en 8×8: asfalto húmedo, banqueta, callejón, cruce, ladrillo, techos, variaciones dañadas/sucias y charcos.
Objetivo: tiles de 32×32 y atlas 256×256. Sus bordes y uniones todavía no están validados.
architecture.png incluye 6 módulos: Local 24, oficina roja, edificio de oficinas, reja, azotea inaccesible y local cerrado.
Tamaños de producción previstos: fachadas 192×160; reja 128×96; azotea 192×128; ventanas 32×48; puertas 48×80.
Actualmente son módulos ilustrados; faltan separación, pivotes y ajuste a la cuadrícula.
No convertir estas ilustraciones en un fondo único para reemplazar el futuro tileset modular.

## Efectos
effects y effects_v02 presentan 10 filas por 6 fases. La segunda versión no resuelve todos los halos, por lo que ninguna se considera definitiva.
| Efecto | Celda prevista | Fases |
|---|---|---:|
| Cuchillo | 64×64 | 6 |
| Sangre pequeña | 32×32 | 6 |
| Impacto | 32×32 | 6 |
| Sombras pixeladas | 64×32 | 6 variantes |
| Lluvia | 32×64 | 6 |
| Reflejos | 64×32 | 6 |
| Destello de farol | 64×96 | 6 |
| Objetivo | 24×32 | 6 |
| Daño | 32×32 | 6 |
| Polvo/niebla | 64×64 | 6 |

## Retratos y menú
portraits.png: Nico preocupado, serio y decidido, más El Jefe por teléfono, en una lámina de cuatro imágenes.
Objetivo: 128×128 por retrato; 1 cuadro por expresión. La lámina actual no tiene cuatro celdas cuadradas, requiere recorte y composición.
menu.png: diseño cinematográfico, sin pixel art, título THE LAST ROUTE, Nueva partida, Continuar, Controles y Salir.
menu_background.png: fondo limpio separado, sin título ni botones.
Objetivo de exportación del menú: 1920×1080; mostrar a 1152×648. No se ha exportado todavía en esas dimensiones.
Para el juego: resolución interna 576×324, escala exacta ×2, texturas Nearest y posiciones ajustadas a píxel.

## Medidas reales de los PNG
| Grupo | Dimensiones reales |
|---|---|
| Hoja de estilo | 1536×1024 |
| Hojas de personajes salvo ataque Nico | 1086×1448 |
| Ataque Nico | 1087×1447 |
| Objetos | 1402×1122 |
| Tiles | 1254×1254 |
| Arquitectura | 1536×1024 |
| Efectos v01 y v02 | 1024×1536 |
| Retratos | 2172×724 |
| Menú, fondo y triptico de nivel | 1672×941 |

image-metadata.json registra las dimensiones y formato de cada archivo medidos desde los PNG.
Los personajes, objetos, arquitectura y efectos contienen canal alfa y píxel transparente en la esquina examinada. Eso no garantiza que todos los bordes o halos estén correctos.

## Incidencias que impiden cerrar la fase 1
1. Normalizar al tamaño nativo sin suavizado ni pérdida de legibilidad. No basta con reducir imágenes grandes automáticamente.
2. Corregir las ocho direcciones de Nico: algunas filas diagonales se parecen demasiado o apuntan al lado incorrecto.
3. Verificar pivote y continuidad de cada cuadro; probar caminatas en bucle para descartar deslizamiento y saltos.
4. Corregir mano del cuchillo y continuidad del paquete, que desaparece o cambia de posición en algunos cuadros.
5. Limpiar halos y alfa de efectos; mantener sombras pixeladas, sin desenfoque.
6. Separar objetos y módulos; uniformar perspectiva y densidad de píxel.
7. Corregir bordes y comprobar repetición del tileset en mosaicos de prueba.
8. Preparar retratos cuadrados y exportaciones definitivas del menú.
9. Presentar las versiones finales, con previews animados, para aprobación explícita antes de importar o programar.

## Alcance de la aprobación
Este paquete permite revisar personajes, atmósfera, paleta, objetos y composición.
No es una entrega de la fase 1 completa ni una solicitud para iniciar la fase 2.
Una aprobación del estilo no reemplaza la aprobación de todos los assets finales.
No avanzar a Godot hasta corregir los puntos anteriores y recibir aprobación explícita.

## Procedencia
Imágenes generadas con la herramienta integrada image_gen. Sin CLI ni API externa personalizada.
asset-manifest.json conserva los prompts exactos y las rutas de los originales.
No hay audio producido en esta fase; assets/audio está reservado.

