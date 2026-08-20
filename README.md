# GUANDITO — Vertical Slice: Sector 07

Vertical slice 2D de acción/plataformas para **Godot 4.x estable + GDScript**. Sector 07 conecta el combate de Fase 2 con un capítulo industrial continuo de siete zonas.

## Abrir y ejecutar

1. Instala Godot 4.x estable compatible con el formato 4.7 del proyecto.
2. Importa esta carpeta mediante `project.godot`.
3. Pulsa **F5** para ejecutar `scenes/levels/sector07.tscn`.

Resolución lógica: **480 × 270**. Ventana inicial: 960 × 540. El proyecto usa viewport stretch, nearest-neighbor y pixel snapping.

Validado con **Godot 4.7.2 stable**: la arena abrió en el editor sin errores y `tests/combat_phase2_smoke.gd` completó todas sus comprobaciones. Aun así, los timings deben validarse manualmente con teclado y mando reales.

## Controles

| Acción | Teclado | Mando genérico |
|---|---|---|
| Mover / control aéreo | A/D o flechas | Stick izquierdo / D-pad |
| Correr | Shift | LB / L1 |
| Saltar | Espacio | A / Cross |
| Dash terrestre ofensivo | L | B / Circle |
| Light / combo ×3 | J o Z | X / Square |
| Heavy launcher | K o X | Y / Triangle |
| Dodge modular | Q | RB / R1 |
| Alternar Piernas Mk-I | M | Back/View |
| Alternar Sobrecarga Evasiva | N | — |
| Pausa | Escape | Start |

Debug, solo en builds de desarrollo: **F1** hitboxes/hurtboxes, **F2** +50 XP, **F3** curar y **F4** HUD de combate.

## Kit inicial

- Caminar/correr, salto variable y control aéreo parcial.
- Coyote time y jump buffering.
- Dash exclusivamente terrestre, ofensivo y sin invulnerabilidad.
- Dash → Light 1 con cancel inmediato y conservación parcial de impulso.
- Combo Light 1 → 2 → 3 con input buffering.
- Heavy con startup comprometido y knockback vertical de launcher.
- Un Light aéreo por salto; no existe Heavy aéreo, dash aéreo ni doble salto.

## Sobrecarga Evasiva Mk-I

Resource `resources/modules/overdrive_evasion_mk1.tres`, categoría Legs y costo 2. Al equiparlo desbloquea `dodge`:

1. `startup`: breve y vulnerable.
2. `evade`: 0.13 s de invulnerabilidad; un impacto detectado registra Perfect Evade.
3. `exposed`: 0.24 s vulnerable con daño ×2.

El reactor naranja, aro de advertencia y símbolo de exposición complementan el color. Dash y dodge tienen estados, reglas, feedback y cooldowns independientes.

## Combat values

| Ataque | Daño | Startup | Active | Recovery | Hitstop | Hitstun | Knockback |
|---|---:|---:|---:|---:|---:|---:|---|
| Light 1 | 10 | 0.045 | 0.075 | 0.090 | 0.028 | 0.160 | (95, -25) |
| Light 2 | 12 | 0.050 | 0.080 | 0.100 | 0.032 | 0.190 | (115, -32) |
| Light 3 / Pulse | 18 | 0.070 | 0.100 | 0.180 | 0.055 | 0.300 | (205, -70) |
| Heavy / Launcher | 30 | 0.190 | 0.120 | 0.260 | 0.085 | 0.340 | (185, -285) |
| Air Light | 16 | 0.060 | 0.120 | 0.140 | 0.045 | 0.240 | (145, 85) |
| Dash → Light | 10 | 0.020 | 0.130 | 0.120 | 0.035 | 0.260 | (125, -38) |

Ventana de combo Light 1/2 y Dash-Light: 0.32 s. Buffer: 0.22 s. El Air Light conserva 72% de la velocidad vertical al conectar.

| Movimiento | Velocidad | Duración | Cooldown | Invulnerabilidad | Exposición |
|---|---:|---:|---:|---:|---:|
| Dash | 265 px/s | 0.14 s | 0.38 s | Ninguna | Ninguna |
| Dodge | 225 px/s | 0.035 + 0.13 + 0.24 s | 0.85 s | 0.13 s | 0.24 s, daño ×2 |

## Arquitectura relevante

```text
resources/data/attack_data.gd              datos comunes de ataques y feedback
resources/data/attack_*.tres               balance por ataque
resources/modules/module_data.gd           datos serializables de módulos
resources/modules/overdrive_evasion_mk1.tres
scripts/components/player/guandito_player.gd
scripts/components/player/guandito_visual.gd
scripts/components/hitbox_component.gd
scripts/components/hurtbox_component.gd
scripts/enemies/training_bot.gd
scripts/effects/impact_fx.gd                flashes, ondas y audio placeholder
scripts/systems/pixel_camera.gd             follow + shake reutilizable
scripts/systems/game_manager.gd             FX, shake y debug
scripts/ui/hud.gd                           HUD normal + combat debug
scenes/levels/sector07.tscn                 capítulo principal
scripts/levels/sector07.gd                  layout procedural y progresión
scripts/level/                               checkpoints, puertas, elevadores y triggers
scripts/enemies/sector_enemy.gd             Scrapper, Bulwark y Sentry
scripts/enemies/vlr03_hound.gd              miniboss de cuatro patrones
scripts/audio/industrial_ambience.gd         ambiente procedural placeholder
```

## Concept art

Las referencias oficiales son `assets/concept/assetsconceptguandito_concept.png.png` y `assets/concept/assetsconceptsector_07_level_design.png.png`. Los placeholders respetan su recorrido, paleta, siluetas enemigas y Martillo de Pulso Cinético. No se extrajeron sprites finales automáticamente.

## Sector 07

1. **Sótano — Despertar:** espacio seguro para movimiento, salto y lectura ambiental.
2. **Primer Contacto:** dos Scrappers enseñan el combo.
3. **Sala de Bombeo:** elevador, plataformas móviles, Scrapper y Sentries para dash/cancel.
4. **Conductos:** pasarelas superiores, dos rutas breves y recompensas de XP.
5. **Ensamblaje:** encuentro combinado con Scrapper, Bulwark y Sentry.
6. **VLR-03 HOUND:** carga, salto con impacto, garra y ráfaga. Su derrota genera el módulo.
7. **Salida:** el módulo abre la compuerta; un Sentry permite practicar dodge antes de revelar KORA y La Aguja.

Checkpoints: después de Primer Contacto, después de Conductos, antes del HOUND y tras la recompensa.

## Validación y limitaciones

- Verificado estáticamente: rutas `res://`, inputs semánticos, datos explícitos de ataques, ausencia de dash aéreo y ramas de riesgo del dodge.
- La arena se ejecutó visualmente en Godot 4.7.2 con HUD, Guandito y TrainingBots cargados y 0 errores del editor.
- El smoke test headless comprueba run/jump/air control/landing, dash vulnerable, Dash→Light, buffering, Heavy interrumpible, launcher, restricción de Heavy aéreo, equipamiento, fases del dodge, Perfect Evade, daño ×2, limpieza de exposición y muerte durante Exposed.
- La automatización de ventanas no puede sostener entradas con fidelidad suficiente para juzgar game feel; timings, mezcla de audio y amplitud del shake aún requieren una sesión humana con teclado y mando.
- Visuales, martillo, ondas, estelas y sonidos son placeholders procedurales.
- Todavía no hay animaciones de sprites, cancelaciones avanzadas, juggling, wall splat, parry ni guardado.

Ejecutar pruebas automatizadas:

```powershell
Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/combat_phase2_smoke.gd
Godot_v4.7.2-stable_win64.exe --headless --path . --script res://tests/sector07_smoke.gd
```
