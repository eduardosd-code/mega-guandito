# Artifacts de validación

Capturas generadas por pruebas visuales locales. No son assets runtime.

## playtest/

Informes JSON de telemetría escritos por `scripts/systems/playtest_recorder.gd` al terminar cada sesión de juego en build de desarrollo (autoguardado cada 20 s y volcado final al cerrar). Cada informe registra: distancia de Dash→Light, frecuencia de Perfect Evade, golpes con daño ×2 por exposición, intentos de Heavy castigados con progreso de startup, entradas perdidas y una línea de tiempo de eventos. Fuerzar grabación en headless con la variable `GUANDITO_PLAYTEST=1`.
