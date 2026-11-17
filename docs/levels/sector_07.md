# Sector 07 — instalación abandonada

## Estructura y ruta

Sector 07 es la escena principal del proyecto. Conserva la silueta del concept oficial: una ruta predominantemente horizontal, quebrada por desniveles, pasarelas, dos elevadores y plataformas móviles. El recorrido jugable es:

`Sótano → Primer contacto → Sala de bombeo → Conductos → Ensamblaje → Hangar HOUND → Superficie`

No requiere backtracking. Dos ramales elevados cortos en Conductos y Ensamblaje contienen secretos de XP.

## Zonas y objetivos

1. **Sótano / Despertar (0–690):** secuencia técnica saltable de menos de cinco segundos, cápsula de mantenimiento, movimiento y salto sin enemigos.
2. **Primer contacto (690–1420):** un Scrapper aislado y luego dos Scrappers. Enseña ataque, combo, daño y XP. Checkpoint al salir.
3. **Sala de bombeo (1420–2480):** un Sentry visible, luego Scrapper + Sentry, plataformas móviles y tres escapes de vapor intermitentes. Enseña Dash, proyectiles, posicionamiento y Dash → Light.
4. **Conductos de servicio (2480–3360):** pausa de exploración, ruta principal, pasarelas opcionales, un guardián y primer secreto. Checkpoint al final.
5. **Zona de ensamblaje (3360–4260):** Bulwark solo; Bulwark + Scrapper; 2 Scrappers + Sentry; arena final con 2 Scrappers + Bulwark + Sentry. La puerta cierra únicamente en el combate final y vuelve a abrir al despejarlo.
6. **VLR-03 HOUND (4260–5050):** checkpoint inmediato, alerta breve, barra de vida y la IA validada en Combat Lab sin modificaciones específicas del nivel. La salida permanece cerrada hasta recoger el módulo.
7. **Salida / KORA (5050–5750):** checkpoint de recompensa, Sentry de práctica para Dodge, luz exterior, skyline provisional de KORA y silueta dominante de La Aguja.

## Checkpoints y respawn

- `cp_contact` en x=1250, después de Primer contacto.
- `cp_service` en x=3040, al final de Conductos.
- `cp_boss` en x=4250, antes de HOUND.
- `cp_reward` en x=5020, después de HOUND.

Cada checkpoint captura posición, nivel, XP y enemigos derrotados. Al morir se restauran vida, posición, XP y los enemigos vencidos después del último checkpoint; los enemigos anteriores permanecen derrotados. Los proyectiles se limpian. HOUND reaparece si aún no fue derrotado. Una recompensa ya obtenida permanece durante la sesión.

## Secretos

- Núcleo de datos en la pasarela superior de Conductos: 35 XP.
- Celda de reactor en la ruta elevada de Ensamblaje: 50 XP.

No se agregó una economía nueva.

## HOUND y módulo

HOUND conserva Charge, Pounce, Claw Combo, Energy Burst, stagger y ventanas de recuperación del Combat Lab. Al morir reproduce death/destroy FX y crea un `ModulePickup`. Al tocarlo, Guandito instala automáticamente **Sobrecarga Evasiva Mk-I**, la equipa con el sistema real de módulos y abre la compuerta. Sector 07 comienza con esta mejora bloqueada.

## Presentación y salida

El despertar usa una capa negra con mensajes GND-01, núcleo, motores, error de memoria y restauración de control; cualquier entrada lo omite. La salida cambia a una paleta fría, muestra un skyline provisional y presenta `KORA // LA AGUJA`, seguido de `SECTOR 07 // ESCAPE COMPLETE`.

## Duración objetivo

El presupuesto de pacing es 11:00: 1:00 despertar, 1:30 contacto, 1:45 bombeo, 1:15 conductos, 2:00 ensamblaje, 2:30 HOUND y 1:00 salida. Debe validarse con jugadores humanos antes de cerrar balance.

## Debug

En builds debug: F2 cura, F3 avanza por checkpoints, F4 teletransporta al preboss y F5 desbloquea Dodge. Combat Lab sigue disponible en `scenes/levels/combat_lab.tscn`.

## Placeholders

Geometría, paredes, tuberías, maquinaria, luces, skyline de KORA, La Aguja, vapor y audio ambiental siguen siendo provisionales generados con primitivas y hooks. Los sprites y FX existentes de Guandito y enemigos sí se reutilizan.
