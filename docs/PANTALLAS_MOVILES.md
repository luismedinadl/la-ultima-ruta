# Pantallas móviles

Android y iOS usan viewport expandido y escalado proporcional. PC conserva 576x324 con escalado entero. Para simular una pantalla ancha en PC: ejecutar con argumentos --responsive --touch y cambiar el tamaño de la ventana.

El escenario mantiene su altura de diseño de 324 unidades. La cámara ajusta el ancho visible y respeta los extremos de cada mapa. En tablets se ajusta el zoom para no mostrar espacio fuera de la carretera. No se modificaron los assets ni sus proporciones; se mantiene Nearest. El escalado fraccional permite llenar tamaños que no son múltiplos exactos de la resolución base.

responsive_layout.gd administra una zona central para menús, avisos y documentos. HUD y botones táctiles se anclan a los bordes de la zona segura. Los fondos cubren todo el viewport; las ilustraciones se recortan proporcionalmente para llenar la pantalla. La lluvia usa el viewport actual.

Android tiene edge_to_edge e inmersión activados. La zona segura se consulta al sistema y se convierte a coordenadas del juego; evita poner botones bajo recortes de pantalla. Comprobar en dispositivo físico al volver a exportar.

Pruebas automatizadas: tests/responsive_checks.gd (usar --responsive --touch); tests/responsive_input_checks.gd (sin argumentos, comprueba primero la configuración de PC). Se probaron 1152x648, 1560x720, 1600x720 y 1600x1200, límites de cámara en los ocho niveles, ocho escenarios de supervivencia, pausa y controles dentro de una zona segura simulada. El segundo ensayo verifica eventos táctiles simultáneos, diálogo y pausa.

Estas pruebas se ejecutaron en Windows simulando tamaños móviles. No equivalen a una prueba física en Android. Exportar una nueva APK para comprobar el S25 Ultra; las APK anteriores no reciben estos cambios.
