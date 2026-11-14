# Caminata lateral y diagonal de Nico

Se reemplazaron los cuadros de caminata e idle laterales y diagonales de cuchillo y pistola por una hoja transparente con 36 poses (seis por orientación y arma). Las direcciones opuestas comparten la animación reflejada. La fila trasera de cuchillo tiene orientación NE en el archivo; su reflejo se trata por separado.

La imagen original se conserva sin modificaciones. El JSON define recortes sin vecinos y puntos de alineación de cabeza. Se mantienen la altura de 55 píxeles, el filtro Nearest y un torso estable. Reposo y caminata comparten la primera pose; el reposo queda detenido. Cambiar de dirección conserva la fase del paso. No se modifica la velocidad de desplazamiento, las colisiones ni el arte vertical o de escopeta.

Arte: herramienta integrada image_gen, hoja final nico_lateral_walk_v03.png. Instrucciones de generación en nico_lateral_walk_v03.prompt.json.

Validación: tests/nico_walk_checks.gd cubre ambas armas en las seis direcciones, continuidad al girar, transición a reposo, avance temporal y regreso a ataques. Se repiten las pruebas de armas y controles táctiles.

## Corrección de reproducción en movimiento
La prueba anterior observaba el sprite aislado y no evaluaba la percepción del paso al desplazarse. Ahora nico_live_gait_checks.gd recorre el nivel mediante los controles y verifica las seis direcciones con ambas armas. El reposo usa la pose cerrada 1 del atlas. La secuencia es 1,2,0,4,5,3: las poses de paso cerrado duran más que las de extensión. La fase avanza por distancia realmente recorrida (44 píxeles por ciclo) y no por tiempo. No se dan pasos ni sonidos de pisadas al estar bloqueado contra un obstáculo. Se mantienen el arte y la velocidad de desplazamiento.
