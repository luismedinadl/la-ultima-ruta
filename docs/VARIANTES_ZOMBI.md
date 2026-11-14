# Variantes del zombi básico

Se mantienen cuatro apariencias: el hombre mayor original, la mujer joven de sudadera roja, la mujer adulta de abrigo ocre y el hombre joven de chaqueta azul.

Cada grupo de cuatro zombis básicos recibe las cuatro apariencias en orden aleatorio. La selección ocurre una sola vez al crear el enemigo. Su apariencia se conserva durante toda su vida y al morir. No se cambian las cantidades de enemigos de las oleadas.

Los zombis básicos que reaccionan al ruido también pueden tener estas apariencias. Los resistentes, perros, Huecos y jefes conservan sus diseños y estadísticas.

## Recursos

- `assets/enemies/zombie_variants/1`: mujer joven.
- `assets/enemies/zombie_variants/2`: mujer adulta.
- `assets/enemies/zombie_variants/3`: hombre joven.
- Cada carpeta contiene walk, attack, hurt, death y regions.json.
- Reposo: primer cuadro de caminar, detenido, para evitar cambios bruscos de postura.
- Ocho orientaciones; caminar, ataque, daño y muerte tienen seis cuadros. En dos muertes se mantiene el último cuadro de cadáver durante el sexto cuadro.
- Las hojas masculinas tienen siete orientaciones dibujadas; la orientación este utiliza el reflejo horizontal de oeste.
- Recortes y pivotes individuales en regions.json; los PNG originales no se alteran mediante código. Altura de referencia en pantalla: 52 píxeles. Filtrado Nearest del proyecto.
- `scripts/zombie_variant_art.gd` carga y comparte SpriteFrames entre instancias, y controla la selección aleatoria.

## Validación

`tests/zombie_variant_checks.gd`: selección de las cuatro apariencias, cuadros y orientaciones, regiones dentro de la textura, salud, velocidad, colisión, daño de ataque, reacción al daño, muerte única con cadáver y percepción del ruido. Resultado: cero fallos.

`tests/weapon_checks.gd`: disparos, bloqueo por vehículos, munición, recarga, interrupción por daño y cambio de arma. Resultado: cero fallos.

Revisión visual dentro de Godot de los seis cuadros de caminar en todas las orientaciones y cuadros de ataque, daño y muerte. Se corrigió la separación de la hoja masculina para evitar restos de otros personajes sobre la cabeza.

Los procesos de pruebas muestran avisos de recursos pendientes al cerrar el motor; las comprobaciones funcionales anteriores pasan. No se ha realizado una prueba de rendimiento en un teléfono físico.
