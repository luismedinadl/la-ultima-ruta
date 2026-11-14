# Nuevo aspecto del resistente

Diseño aprobado: infectado corpulento de cabello oscuro, brazos gruesos, piel rojiza y chaleco granate. Sustituye al hombre mayor teñido de rojo cuando el enemigo tiene `resistant = true`.

Los recursos están en `assets/enemies/resistant/`: walk, attack, hurt, death y regions.json. Cada hoja contiene cinco orientaciones y seis cuadros; las orientaciones restantes se reflejan horizontalmente para cubrir las ocho direcciones. Los metadatos corrigen la orientación de los cuadros de golpe y los recortes individuales. Reposo mantiene el primer cuadro de caminar para evitar cambios bruscos de postura. La muerte no se repite y conserva el cadáver.

Altura visual de referencia: 64 píxeles. La paleta rojiza forma parte del dibujo, sin aplicar el tinte anterior. La barra de salud se sitúa encima de la cabeza.

Se conservan la salud base de 190 (escalada por dificultad), velocidad base de 19, daño de 22, colisión, frecuencia de ataque y cantidad de resistentes de cada oleada. Los cuatro diseños básicos y los enemigos especiales conservan su selección anterior.

Validación: `tests/zombie_variant_checks.gd` comprueba selección, orientaciones, regiones, estadísticas, daño, cadáver y percepción del ruido, incluyendo al resistente. Revisión visual de los seis cuadros de caminar en las ocho direcciones y de ataque, daño y cadáver en Godot.
