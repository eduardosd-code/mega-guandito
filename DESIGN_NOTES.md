# GUANDITO — notas de diseño

## Combat Philosophy

**IMPULSO + RIESGO + IMPACTO.**

Guandito debe moverse con rapidez mecánica y conectar golpes pesados. La secuencia deseada es moverse → saltar → hacer dash → cancelar → atacar → reposicionarse. Permanecer quieto y repetir un botón no debe ser la estrategia dominante.

- **Impulso:** carrera, control aéreo y Dash → Light sostienen la agresión.
- **Riesgo:** Heavy compromete al jugador; el dodge mal medido produce exposición con daño ×2.
- **Impacto:** hitstop escalonado, knockback, flash, ondas, audio y shake reservado para golpes fuertes.

## Signature Weapon

**Kinetic Pulse Hammer / Martillo de Pulso Cinético.**

Herramienta industrial modular capaz de descargar energía cinética al impacto. Light 3 produce el pulso característico; Heavy usa su masa y descarga para elevar enemigos. Debe conservar metal blanco/grafito, carcasa verde y energía verde brillante del concept oficial.

## Starting Kit

- Ground Movement
- Jump
- Air Control
- Ground Dash sin i-frames
- Light Combo ×3 con buffering
- Heavy Attack / Launcher
- Basic Air Attack
- Dash → Light Cancel

No incluye dash aéreo, doble salto, Heavy aéreo, parry, bloqueo ni dodge base.

## Unlockable

**Overdrive Evasion Mk-I / Sobrecarga Evasiva Mk-I**

Módulo Legs de costo 2 que desbloquea dodge. Sus fases son Startup vulnerable, Evade con i-frames y Exposed con daño ×2. Perfect Evade solo registra y comunica el evento; no concede recompensa mecánica todavía.

## Game-feel targets

- Light 1 debe aceptar con facilidad una entrada temprana para Light 2.
- Light 2 debe mantener al bot cerca.
- Light 3 debe ser legible como pulso mediante recovery, hitstop, onda, audio y shake moderado.
- Heavy debe anticiparse visualmente, interrumpirse al recibir daño y lanzar al TrainingBot.
- Air Light solo amortigua parcialmente la caída al conectar; no permite flotar.
- Dash debe ser ofensivo y peligroso; Dodge debe leerse como herramienta defensiva separada.

## Future Concepts

- Air Dash
- Double Jump
- Advanced Modules
- Perfect Evade Modules

### Kinetic Momentum System — documentado, no implementado

Una posible mecánica futura permitiría generar impulso mediante movimiento agresivo, dash y golpes conectados para alimentar el Martillo de Pulso Cinético. No debe implementarse hasta demostrar que el combate base ya es divertido sin un medidor adicional.

## Próximo paso recomendado

Realizar una sesión manual de 15–20 minutos con teclado y mando. Registrar especialmente fallos de input, distancia recorrida por Dash→Light, frecuencia de Perfect Evade y si Heavy resulta castigable. Ajustar primero tiempos y velocidades; después producir animaciones, VFX y SFX más elaborados.

## Sector 07 — Instalación Abandonada

Sector 07 es un escape ascendente mediante avance horizontal, elevadores, pasarelas y cambios de cota; no una subida vertical continua. El recorrido sigue el concept oficial: despertar → contacto → bombeo → conductos → ensamblaje → HOUND → superficie.

La progresión enseña sin paneles invasivos. Mensajes breves aparecen en el mundo y cada arena exige la siguiente herramienta: combo contra Scrapper, dash contra Sentry, Heavy contra Bulwark y lectura de telegraphs contra HOUND. Sobrecarga Evasiva solo se desbloquea después del miniboss y se practica antes de contemplar KORA y La Aguja.

Los fondos procedurales actuales establecen acero, grafito, óxido, ámbar, energía verde, tuberías y escala industrial. TileSets, sprites, iluminación, partículas y audio producido siguen pendientes de sustitución artística.
