# Nivel 8: cruce y combate final

Los cuatro civiles atraviesan la puerta de carga abierta mediante puntos de paso dentro de su abertura. Continúan caminando hasta el encuentro con el Jefe y después hacia el barco.

Los dos guardias avanzan, disparan tres ráfagas y reciben el golpe del Anclado. Sus animaciones terminan con los cuerpos en el suelo. El Jefe huye; los guardias no. No aparecen refuerzos de Huecos durante este combate.

El Anclado pasa de 1600 a 2400 de vida. Su velocidad de aproximación pasa de 39/49 a 55/68 y su carga de 205/235 a 250/290, según la fase. Conserva los avisos previos a sus ataques y sus ventanas de recuperación.

El fondo del puerto ahora cubre todo el límite derecho de la cámara, incluida la pantalla de resultados.

## Arte nuevo

Generado con image_gen integrada, tomando como referencia los guardias aprobados. PNG transparente de 1536 × 1024: cuatro filas de seis cuadros (disparo y muerte para cada guardia). Los recortes y anclajes están en corporate_guards_combat.json. No modifica los sprites originales de reposo o caminata.

Prompt: Create production game sprite sheet, reference is the exact two corporate guard identities and uniforms to preserve. Dark charcoal tactical clothes with orange patches, male bearded guard in cap and female brown-haired guard, rifles. Crisp pixel art, 3/4 overhead, transparent background. Layout EXACTLY 6 columns and 4 rows with large clear spacing, all full bodies isolated in uniform cells. Row1 male firing rifle to the RIGHT: six frames of raising rifle, aiming, small muzzle flash, recoil, recovery, aiming. Row2 male death: six frames impact recoiling, knees buckle, falling, hitting ground, lying still, final corpse lying flat on ground. Row3 female firing RIGHT same six phases. Row4 female death same six phases ending flat on ground. No graphic gore, no dismemberment, just fallen bodies and rifles. Keep head/body proportions and uniform of reference, same character size throughout rows (do not enlarge prone frames). Feet/ground on same local baseline; ample empty margin around each sprite and between columns so prone figures do not overlap. No text, grid, scene, background, or added characters. Landscape sheet may be 1536x1024 or larger to fit 24 separated sprites.

## Verificación

Pruebas automatizadas: harbor_finale_polish_checks, harbor_checks, harbor_combat_checks, harbor_access_checks y harbor_story_revision_checks. Cubren progresión, colisiones, cruce, disparos, muerte de guardias, ausencia de refuerzos, velocidades, restauración y fondo. Capturas revisadas del cruce, guardias disparando y caídos, y pantalla final. Algunas pruebas generales notifican recursos pendientes al cerrar su entorno de prueba; se distinguen de los resultados funcionales.

La exportación APK anterior no incluye estos cambios; es necesario exportar otra para probarlos en Android.
