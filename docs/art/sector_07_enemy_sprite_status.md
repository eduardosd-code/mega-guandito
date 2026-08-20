# Sector 07 enemy sprite status

Source: `docs/concept/sector_07_enemy_spritesheet.png` (1536×1024 production sheet).

The sheet contains labels, borders, effects, and unevenly spaced poses. Automatic equal-width slicing produced partial bodies, so it was rejected. Runtime atlases currently repeat one conservatively isolated scale-reference pose per enemy. They are intentionally marked `PLACEHOLDER`; no missing art was invented or AI-reconstructed.

| Enemy | Animation | Status | Frames | Notes |
| --- | --- | ---: | ---: | --- |
| Scrapper | idle | PLACEHOLDER | 6 | Stable feet pivot; clean animation frames required. |
| Scrapper | run | PLACEHOLDER | 8 | Repeated approved silhouette. |
| Scrapper | attack_1 | PLACEHOLDER | 4 | Gameplay event remains script-driven. |
| Scrapper | attack_2 | PLACEHOLDER | 5 | Sheet poses cannot be split safely. |
| Scrapper | hit | PLACEHOLDER | 3 | Repeated approved silhouette. |
| Scrapper | death | PLACEHOLDER | 6 | Clean death frames required. |
| Bulwark | idle | PLACEHOLDER | 6 | 96×96 canvas preserves heavy scale. |
| Bulwark | walk | PLACEHOLDER | 6 | Repeated approved silhouette. |
| Bulwark | attack_hammer_fist | PLACEHOLDER | 5 | Gameplay event remains script-driven. |
| Bulwark | attack_charge | PLACEHOLDER | 6 | Trail remains separate from collision. |
| Bulwark | attack_backhand | PLACEHOLDER | 4 | Arc is not baked into hurtbox. |
| Bulwark | hit | PLACEHOLDER | 3 | Repeated approved silhouette. |
| Bulwark | death | PLACEHOLDER | 7 | Clean death frames required. |
| Sentry | hover_idle | PLACEHOLDER | 6 | Center pivot on 64×64 canvas. |
| Sentry | move | PLACEHOLDER | 4 | Repeated approved silhouette. |
| Sentry | pulse_shot | PLACEHOLDER | 5 | Projectile remains an independent node. |
| Sentry | triple_pulse | PLACEHOLDER | 7 | Gameplay currently uses the validated single-shot behavior. |
| Sentry | hit | PLACEHOLDER | 3 | Repeated approved silhouette. |
| Sentry | death | PLACEHOLDER | 6 | Clean death frames required. |
| HOUND | idle | PLACEHOLDER | 6 | 160×96 canvas preserves its long silhouette. |
| HOUND | walk_prowl | PLACEHOLDER | 6 | Repeated approved silhouette. |
| HOUND | charge | PLACEHOLDER | 5 | Existing charge timing unchanged. |
| HOUND | pounce | PLACEHOLDER | 6 | Existing landing hitbox unchanged. |
| HOUND | claw_combo | PLACEHOLDER | 6 | Existing claw hitbox unchanged. |
| HOUND | energy_burst | PLACEHOLDER | 8 | Projectiles remain independent nodes. |
| HOUND | hit | PLACEHOLDER | 3 | Repeated approved silhouette. |
| HOUND | death | PLACEHOLDER | 8 | Clean destruction frames required. |

## Import and collision policy

- Global pixel-art filtering remains nearest-neighbor with transform and vertex snapping enabled.
- Runtime PNGs have transparent backgrounds and no embedded labels or panel frames.
- `AnimatedSprite2D` is visual-only. Existing body collisions, hurtboxes, attack hitboxes, damage, HP, AI, cooldowns, and XP are unchanged.
- Sentry projectiles and HOUND energy projectiles reuse `EnemyProjectile`, which owns velocity, damage, lifetime, hit collision, and destruction independently of enemy sprites.
- Sheet FX are not extracted because they overlap presentation elements or bodies; existing reusable gameplay FX remain unchanged.

## Replacement workflow

Run `tools/build_sector07_enemy_sprites.ps1` after replacing the production sheet or adjusting verified source bounds. Clean animator-exported frames should replace the placeholder atlases without changing the scene or gameplay architecture.
