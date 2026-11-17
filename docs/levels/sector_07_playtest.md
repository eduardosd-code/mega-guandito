# Sector 07 — registro de playtest

Fecha: 2026-08-21

## Metodología

Se ejecutaron tres recorridos automatizados headless en Godot 4.7.2 mediante `tests/sector07_playtest.gd`. Las rutas usan tiempo acelerado para validar estados y bloqueos; el tiempo jugable de 11:00 es un modelo de pacing basado en el presupuesto de cada zona, no una medición humana. Sigue pendiente una sesión manual completa con cronómetro.

## Run 1 — ruta normal

- Automatización: 4.23 s.
- Recorrió checkpoints, manifiesto de enemigos, activación y derrota de HOUND, recogida del módulo, compuerta y salida.
- Resultado: PASS.
- No se detectaron softlocks en la ruta crítica.

## Run 2 — intento de ruptura

- Automatización: 3.15 s.
- Derrotó un enemigo después de checkpoint, murió y comprobó su restauración.
- Entró en la arena final, verificó cierre de puerta, eliminó el grupo, comprobó apertura y volvió hacia atrás.
- Resultado: PASS.
- XP y enemigos regresan a la instantánea del checkpoint, evitando farmeo obvio por muerte.

## Run 3 — recorrido y timing

- Automatización estructural: 0.08 s.
- Modelo de pacing: 11:00.
- Verificó 18 enemigos regulares, un HOUND, puerta de recompensa cerrada y presupuesto dentro de 8–12 minutos.
- Resultado: PASS.

## Regresiones

- `tests/sector07_smoke.gd`: PASS.
- `tests/phase7_combat_lab_smoke.gd`: PASS; Combat Lab mantiene Scrapper, Bulwark, Sentry, HOUND y HUD debug.

## Bugs y riesgos conocidos

- Falta validar la duración con una persona; 11:00 es una estimación de diseño.
- La concentración de cuatro encuentros en Ensamblaje necesita ajuste manual de espacios/dificultad.
- La restauración recrea enemigos de todo el nivel; funciona, pero puede producir un pico pequeño de asignaciones al respawn.
- Godot headless informa que no puede escribir `user://logs/godot.log` ni leer certificados del sistema en el sandbox; no afecta las pruebas de gameplay.
- Hay una advertencia de una instancia de ObjectDB al cerrar el playtest acelerado; no se reproduce como error durante el nivel y debe perfilarse en una sesión larga.

## Performance

La escena mantiene menos de veinte enemigos regulares, un miniboss y geometría de primitivas. No se observaron caídas ni errores de física en headless. Queda pendiente perfilar GPU/overdraw cuando exista el art pass definitivo.
