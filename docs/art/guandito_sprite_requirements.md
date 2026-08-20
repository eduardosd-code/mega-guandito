# GUANDITO — Especificación técnica del spritesheet

## Estado actual

Existe una reconstrucción provisional completa en `assets/characters/guandito/sprites/runtime/`: 22 atlas y 92 frames normalizados. Se generó desde las láminas aprobadas y está integrada mediante `GuanditoSpriteLibrary`. El renderer procedural permanece como fallback. Todavía no debe marcarse como arte definitivo porque existen pequeñas variaciones generativas entre frames.

## Formato común

- Canvas: 64×64 px por frame.
- Pivote: `(32, 63)`, centro de los pies.
- Alineación: los pies en la misma coordenada en todos los frames de suelo.
- Fondo: transparente.
- Orientación fuente: derecha; Godot puede reflejar horizontalmente.
- Filtro: nearest-neighbor, sin mipmaps ni suavizado.
- Paleta: grafito/negro, verde oliva oscuro, metal blanco/gris y energía verde lima; naranja/rojo sólo para peligro.
- Elementos fuera de hurtbox: martillo, cables, antenas, estelas y partículas.
- Exportación sugerida: atlas PNG con columnas uniformes y recurso `SpriteFrames` o `AnimationLibrary` asociado.

## Inventario de animaciones

| Animación | Frames | Loop | Duración aprox. | Eventos / notas | FX asociado |
|---|---:|:---:|---:|---|---|
| `idle` | 6 | Sí | 0.8 s | reactor pulsa; estabilización mecánica | glow de reactor |
| `run` | 8 | Sí | 0.53 s | contactos de botas en 2 y 6 | polvo/chispa opcional |
| `jump_start` | 3 | No | 0.08 s | despegue al final | impulso pequeño |
| `jump_up` | 3 | Sí | 0.24 s | pose ascendente | ninguno |
| `fall` | 3 | Sí | 0.24 s | silueta descendente clara | ninguno |
| `land` | 3 | No | 0.07 s | contacto en frame 1 | impacto leve opcional |
| `dash_start` | 2 | No | 0.035 s | iniciar estela | `DashTrailFX` |
| `dash` | 3 | Sí | duración del dash | pose compacta | `DashTrailFX` |
| `dash_end` | 2 | No | 0.05 s | recuperar postura | disipación de estela |
| `light_1` | 4 | No | 0.21 s | hitbox tras 0.045 s | `ImpactLightFX` |
| `light_2` | 5 | No | según `AttackData` | hitbox en fin de startup | `ImpactLightFX` |
| `light_3` | 6 | No | 0.35 s | hitbox + pulso tras 0.07 s | `KineticPulseFX` |
| `heavy_start` | 4 | No | 0.19 s | anticipación vulnerable | carga de reactor |
| `heavy_attack` | 3 | No | 0.12 s | activar hitbox al inicio | `HeavyImpactFX` |
| `heavy_recovery` | 5 | No | 0.26 s | no cancelar vulnerabilidad | residuos de impacto |
| `air_light` | 5 | No | según `AttackData` | única acción aérea | `ImpactLightFX` |
| `dodge_start` | 2 | No | 0.035 s | todavía vulnerable | inicio de energía |
| `dodge_invulnerable` | 3 | Sí | 0.13 s | coincide con i-frames lógicos | `DodgeTrailFX` |
| `dodge_exposed` | 4 | No | 0.24 s | reactor naranja/rojo; ×2 daño | `ExposedFX` |
| `hit` | 3 | No | usar `hitstun` | flash/pose de impacto | impacto enemigo |
| `death` | 7 | No | 0.8–1.0 s | termina inmóvil | chispas opcionales |
| `module_install` | 8 | No | 0.65 s | input bloqueado durante instalación | `ModuleInstallFX` |

Los segundos exactos de combate se obtienen de los archivos `resources/data/attack_*.tres`; el arte debe adaptarse a ellos. La activación de hitboxes continúa controlada por lógica y nunca por el tamaño del sprite.

## Capas opcionales recomendadas

- `base`: cuerpo, armadura, cables y martillo.
- `visor`: expresiones `neutral`, `alert`, `angry`, `surprised`, `happy`, `system_active`.
- `reactor`: `normal`, `low_health`, `module_install`, `dodge`, `exposed`, `kinetic_charge`.
- `fx`: escenas independientes, no incluidas en la hurtbox.

## Checklist de entrega de arte

- Silueta reconocible a escala de juego.
- Ningún frame supera el canvas 64×64.
- Pivote estable sin jitter.
- Placas, sensor lateral, `01`, reactor y visor legibles.
- Martillo tecnológico consistente entre ataques.
- Sin píxeles semitransparentes en el sprite base.
- Validación en idle, carrera, salto, dash, combo, heavy, aéreo, esquiva, daño y muerte.
