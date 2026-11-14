# Nivel 4: Zona de contención

Disponible en Nueva partida → Nivel 4, o al completar el Nivel 3.

## Recorrido

Cinco encuentros finitos: 7, 8, 7, 9 y 8 enemigos. Total: 39, incluidos cuatro perros. Los puntos principales están separados por 50 m. Dos pasos alrededor de barreras vuelven a unirse; el paso superior permite encontrar enemigos distraídos, el inferior entra en combate directo. Ambos se pueden recorrer sin retroceder por el otro.

El registro del supervisor permite leer la primera prueba y conseguir la tarjeta. El segundo documento, cerca de la salida, revela la cancelación de la evacuación civil. E abre y cierra la lectura; movimiento, ataques enemigos y tiempo de ruta se detienen mientras está abierta. El texto se presenta completo y sin límite de tiempo.

## Escopeta y criatura

La escopeta se obtiene con E frente a la salida de emergencia. Tiene cuatro cartuchos cargados, ocho de reserva iniciales y una caja final de cuatro; la reserva admite doce. La pistola conserva su reserva de 36 y sus cajas de doce. Ambas municiones son independientes. Las cajas y botiquines se recogen al pasar.

Q alterna cuchillo, pistola y escopeta. R recarga. Espacio usa ayuda de apuntado; clic apunta al cursor. Cada descarga de escopeta lanza nueve perdigones en un abanico de 32 grados, alcance 210 píxeles. Cada perdigón impacta en el primer cuerpo o pared; el daño se acumula una sola vez por víctima. Cadencia 0,85 s y recarga 1,6 s. Su máxima eficacia requiere acercarse.

El encuentro final sustituye todos los básicos por seis Huecos, acompañados de un resistente y un perro. El Hueco tiene 151 puntos de salud, garras de 26 de daño con 0,43 s de anticipación y una silueta no humana de aproximadamente 72 píxeles. Los perros conservan 113,28 píxeles/s. El desbloqueo de la criatura queda guardado para reutilizarlo en rutas posteriores; aquí solo se implementa hasta el Nivel 4.

## Organización

- `containment_level.gd`: recorrido, lectura, elecciones, encuentros, recogidas y perdigones.
- `shotgun_player.gd`: tercera arma y munición independiente, reutilizando movimiento y combate anteriores.
- `hollow_enemy.gd`: criatura con percepción y navegación compartidas.
- `containment_art.gd`: recortes, pivotes estables, animaciones y textos.
- `ui.gd` / `main.gd`: lector de documentos, HUD, selección de ruta y final.
- `save_game.gd`: validación de puntos seguros, arma, pruebas y recursos.

Los PNG originales no se modifican ni se sustituyen por dibujos mediante nodos. Cada pose tiene un recorte medido y margen estable. Donde un brazo invade el rectángulo de otro cuadro, una exclusión de texeles evita mostrar fragmentos ajenos. Nico conserva unos 55 píxeles de altura. Ocho direcciones mediante cinco orientaciones dibujadas y tres reflejadas. Caminata de seis cuadros, disparo/recarga y daño/muerte de tres; ataque del Hueco de seis. Reposo inmóvil.

## Verificación

Pruebas funcionales: cinco encuentros, documentos y bloqueo de entrada, adquisición y alternancia de armas, municiones independientes, recarga, recogida única, impacto simultáneo sobre tres enemigos, bloqueo de perdigones por paredes, guardado/restauración y final. Recorrido automatizado con el movimiento y combate reales: 39 enemigos eliminados y llegada al final. Pruebas de regresión de los niveles 1, 2 y 3 y de la pistola completadas. Previews renderizadas en Godot para revisar sprites y lectura. Estas pruebas verifican funcionamiento; el ajuste fino de dificultad requiere también tu partida.

Arte generado con la herramienta integrada imagegen. Prompts: `PROMPTS_NIVEL_4.json`, `PROMPTS_ASSETS_CONTENCION.json`, `PROMPTS_NICO_ESCOPETA.json` y `PROMPT_SALIDA_ABIERTA.txt`. Audio funcional en WAV, reemplazable.
