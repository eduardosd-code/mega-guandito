# Sector 07 enemy sprite status

Source: `docs/concept/sector_07_enemy_spritesheet.png` (1536×1024 production sheet).

The production sheet contains labels, borders, effects, and unevenly spaced poses. Automatic equal-width slicing produced partial bodies, so it was rejected. Scrapper uses separate transparent concept PNGs; Bulwark, Sentry, and HOUND use their dedicated JPG sheets under `assets/concept/`, with black backgrounds removed deterministically. Source limitations are documented per animation below.

| Enemy | Animation | Status | Frames | Notes |
| --- | --- | ---: | ---: | --- |
| Scrapper | idle | COMPLETE | 6 | Reconstructed to 64×64 with stable feet pivot. |
| Scrapper | run | COMPLETE | 8 | Isolated from transparent concept source. |
| Scrapper | attack_1 | COMPLETE | 4 | 96×64 visual canvas preserves weapon reach; hitbox remains independent. |
| Scrapper | attack_2 | COMPLETE | 5 | 96×64 visual canvas preserves weapon reach; hitbox remains independent. |
| Scrapper | hit | COMPLETE | 3 | Normalized to 64×64. |
| Scrapper | death | COMPLETE | 6 | Ground-aligned destruction sequence. |
| Bulwark | idle | COMPLETE | 6 | Reconstructed on a 96×96 canvas with stable feet pivot. |
| Bulwark | walk | COMPLETE | 6 | Body silhouettes isolated from the JPG row. |
| Bulwark | attack_hammer_fist | COMPLETE | 5 | 128×96 canvas; detached impact debris excluded where possible. |
| Bulwark | attack_charge | NEEDS_CLEANUP | 6 | Two overlapping source poses were replaced by adjacent clean poses; trail remains separate from collision. |
| Bulwark | attack_backhand | COMPLETE | 4 | 128×96 canvas; arc does not affect the hurtbox. |
| Bulwark | hit | COMPLETE | 3 | Normalized to 96×96. |
| Bulwark | death | COMPLETE | 7 | 128×96 ground-aligned destruction sequence. |
| Sentry | hover_idle | COMPLETE | 6 | Center pivot on 64×64 canvas. |
| Sentry | move | COMPLETE | 4 | Center-aligned floating movement. |
| Sentry | pulse_shot | COMPLETE | 5 | Muzzle state retained; projectile remains an independent node. |
| Sentry | triple_pulse | COMPLETE | 7 | Visual sequence ready; gameplay retains validated firing behavior. |
| Sentry | hit | COMPLETE | 3 | Detached impact particles excluded from the body where possible. |
| Sentry | death | COMPLETE | 6 | 96×64 canvas preserves destruction fragments. |
| HOUND | idle | COMPLETE | 6 | 160×96 canvas preserves its long silhouette and support pivot. |
| HOUND | walk_prowl | COMPLETE | 6 | Six isolated prowl poses. |
| HOUND | charge | COMPLETE | 5 | Five source poses selected; gameplay timing unchanged. |
| HOUND | pounce | COMPLETE | 6 | Six airborne poses; landing hitbox remains independent. |
| HOUND | claw_combo | COMPLETE | 6 | Six body poses; claw hitbox remains independent. |
| HOUND | energy_burst | COMPLETE | 8 | Six source poses plus two authored recovery poses; projectile remains independent. |
| HOUND | hit | COMPLETE | 3 | Dedicated authored recoil progression, normalized to the existing 160×96 canvas. |
| HOUND | death | COMPLETE | 8 | Six source destruction poses plus two authored terminal collapse poses. |

## Import and collision policy

- Global pixel-art filtering remains nearest-neighbor with transform and vertex snapping enabled.
- Runtime PNGs have transparent backgrounds and no embedded labels or panel frames.
- `AnimatedSprite2D` is visual-only. Existing body collisions, hurtboxes, attack hitboxes, damage, HP, AI, cooldowns, and XP are unchanged.
- Sentry projectiles and HOUND energy projectiles reuse `EnemyProjectile`, which owns velocity, damage, lifetime, hit collision, and destruction independently of enemy sprites.
- Sheet FX are not extracted because they overlap presentation elements or bodies; existing reusable gameplay FX remain unchanged.

## Replacement workflow

Run `tools/build_hound_from_concept.ps1` to rebuild the HOUND atlases from the original production source and `assets/concept/HOUND/VLR-03_HOUND_cleanup_source.png`. The cleanup source supplies only the missing hit and transition poses; the build preserves the existing frame counts, 160×96 canvas, bottom pivot, scene setup, and gameplay architecture.
