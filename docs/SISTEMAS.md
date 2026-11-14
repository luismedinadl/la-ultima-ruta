# Sistemas del Nivel 1

## Aplicación — scripts/main.gd
Controla menú, creación/liberación de la ruta, pausa, diálogos de historia y resultado.
El nodo principal procesa siempre para poder reanudar la pausa. El nivel usa PROCESS_MODE_PAUSABLE.
Los diálogos bloquean la simulación de actores con level.blocked. Al cerrar la última línea se libera la acción o se muestra el resultado.

## Interfaz y diálogo — scripts/ui.gd
CanvasLayer con controles nativos y un tema común. Los retratos provienen del atlas aprobado.
El texto se revela a 42 caracteres por segundo. E/Enter completa o avanza la línea.
La interfaz emite comandos; no aplica daño ni genera enemigos. HUD, pausa, controles y resultados comparten tipografía y color.

## Entrada — scripts/controls.gd
Mapea WASD/flechas, Espacio, E/Enter y Escape a acciones de InputMap.
movement y attacking son la interfaz de entrada de los actores.
virtual_move y virtual_attack permiten automatización y una futura fuente táctil; no se ha creado una interfaz móvil.

## Arte — scripts/art.gd
Carga y cachea PNG. AtlasTexture selecciona regiones; SpriteFrames crea secuencias para AnimatedSprite2D.
Orden direccional: S, SO, O, NO, N, NE, E, SE. Seis cuadros por acción/dirección.
Sprites de Nico y zombi se escalan a 0,34; resistente a 0,39. Se utiliza Nearest.
La excepción de NO de Nico se documenta en LEEME.md. El contenido gráfico siempre procede de archivos raster.

## Jugador — scripts/player.gd y scenes/player.tscn
CharacterBody2D con colisión circular a la altura de los pies. Velocidad 84 px/s y salud 100.
Reposo fijo en el cuadro 0 de la misma hoja de caminata; así no cambia la inclinación del cuerpo al arrancar. La caminata conserva seis cuadros a 12 fps con pivote alineado por la zona opaca de la cabeza. La cámara sigue directamente, sin retraso al iniciar o detener el movimiento.
Estados: idle, walk, knife_attack, hurt, death, pickup_package, delivery.
Golpe: 34 puntos, alcance 43 px, aplicación después de 0,17 s, ciclo total 0,49 s.
La ayuda de orientación selecciona un enemigo a menos de 48 px, pero no aumenta el alcance.
Invulnerabilidad tras daño: 0,95 s. El estado de muerte conserva la animación antes del resultado.

## Enemigo — scripts/enemy.gd y scenes/enemy.tscn
Persigue al jugador con separación entre vecinos y un ligero arrastre lateral.
Zombi normal: salud 86, velocidad 19 px/s, daño 15. Resistente: salud 190, velocidad 15, daño 22.
El ataque avisa durante 0,38 s, alcanza 32 px y tiene enfriamiento de 1,5 s.
Recibir daño interrumpe el ataque. Al morir deja de colisionar, emite killed una sola vez y conserva el último cuadro.

## Oleadas y objetivos — scripts/route_plan.gd y scripts/level.gd
RoutePlan contiene cantidades, posiciones relativas y objetivos. No hay generador infinito.
RouteLevel mantiene los estados 0: paquete, 1: oleada 1, 2: camino al cruce, 3: oleada 2, 4: camino a entrega, 5: oleada 3, 6: entrada libre, 7: entregado.
Los cambios dependen de interacción, entrada en la zona o muerte de todos los enemigos activos.
Las oleadas delimitan una arena de 560 px, con barreras visibles en sus extremos. Las barreras desaparecen cuando termina la pelea.
La tercera oleada incluye 6 enemigos en total, uno resistente; no se añade un séptimo.

## Nivel y decoración — scripts/level.gd y scenes/level_01.tscn
Ruta de 2.320 px, caminable entre y=204 y y=306. Inicio en x=160; Local 24 en x=760; cruce en x=1.360; entrega en x=1.960. Cada tramo entre objetivos mide 600 px, equivalentes a 30 metros. Los puntos seguros antiguos se trasladan proporcionalmente al nuevo recorrido, conservando estadísticas y botiquines recogidos.
El mapa combina regiones de tiles con fachadas y props reales. La generación de posiciones es determinista, con semilla fija; no genera arte mediante código.
Vehículos, basureros y barreras seleccionadas tienen colisiones; la decoración pequeña no bloquea el recorrido.
Actores y objetos comparten ordenación por coordenada Y. La cámara tiene seguimiento directo y vibración breve al impactar.
La lluvia se compone de sprites de efecto; su CanvasLayer está debajo del HUD.

## Guardado — scripts/save_game.gd
Escribe un JSON temporal y lo renombra. Valida versión, estado y tipos al cargar.
Conserva posición, salud, bajas, daño, tiempo y botiquines recogidos. Los estados intermedios de combate no se guardan.

## Audio — scripts/audio.gd y assets/audio
Ambiente y drone tienen reproducción cíclica. Los efectos se reproducen en canales temporales que se liberan al finalizar.
Hay cues para pasos, cuchillo, impacto, daño, interfaz, recogida, oleada, muerte y entrega.
Los archivos WAV son sonido provisional funcional, no grabaciones finales.

## Límites de validación
Las pruebas automatizadas comprueban lógica, física de recorrido, daño y renderizado. No sustituyen una sesión humana de dificultad y ritmo.
El recorrido óptimo automatizado dura 7:27 sin diálogos; la duración de primera partida es una estimación pendiente de validación humana.
No hay Nivel 2, armas de fuego funcionales ni controles móviles. La munición es decoración preparada para una futura ampliación.
