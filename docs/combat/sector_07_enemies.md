# Sector 07 — Enemies

Phase 7 keeps the existing `HealthComponent`, `HurtboxComponent`, `HitboxComponent`, `AttackData`, XP, hitstop, projectile, sprite and FX systems. Regular enemies share `SectorEnemy`; HOUND remains a specialized miniboss controller. Gameplay areas and visual FX are independent.

## MNT-04 Scrapper — pressure

- Balance resource: `resources/enemies/scrapper_balance.tres`.
- HP 45; XP 15; move speed 76.
- States: idle, chase, position, attack_1, attack_2, hit, recover, dead.
- Quick Strike: 8 damage, 0.12 s startup, 0.09 s active, 0.16 s recovery.
- Tool Charge: 12 damage, 0.42 s telegraph, 0.34 s active movement, 0.30 s recovery, 2.2 s independent cooldown.
- Decision: Quick Strike at close range; Charge when positioned farther away and available. It has normal hitstun and no armor.

## CRG-12 Bulwark — patience and Heavy

- Balance resource: `resources/enemies/bulwark_balance.tres`.
- HP 140; XP 40; move speed 34.
- States: idle, walk, position, hammer_fist, charge, backhand, armor_broken, hit, recover, dead.
- Hammer Fist: 22 damage, 0.55 s startup, heavy impact FX, 0.52 s recovery.
- Charge: 25 damage, 0.58 s telegraph, 0.52 s movement, charge trail FX, 3.8 s cooldown.
- Backhand: 18 damage, used at close range, 0.28 s startup, 4.5 s independent cooldown.
- Armor: Light damage is applied and feedback remains, but normal hitstun is suppressed.
- Armor Break: a player Heavy/launcher opens a configurable 1.5 s vulnerability and emits `armor_broken` plus the `armor_break` audio hook.
- Charge has temporary hitstun resistance, not invulnerability. Knockback is reduced to 28%.

## OBS-07 Sentry — mobility

- Balance resource: `resources/enemies/sentry_balance.tres`.
- HP 35; XP 20; preferred range 185; movement speed 72.
- States: hover, position, retreat, pulse_shot, triple_pulse, hit, recover, dead.
- Pulse Shot: 10 damage; projectile speed 145; 0.32 s telegraph.
- The projectile is an independent `EnemyProjectile`, has collision, lifetime and impact signal, and does not derive damage from its FX.
- Retreat is permitted once when crowded; Sentry must then fire before retreat becomes available again.
- `enable_alternate_attack` enables three shots at 0.16 s intervals for advanced variants. The base resource leaves it disabled.

## VLR-03 HOUND — system mastery

- Balance resource: `resources/enemies/hound_balance.tres`.
- HP 850; XP 150; medium-high knockback resistance.
- States: dormant, idle, reposition, charge_warning/charge, leap_warning/leap, claw_warning/claw, burst_warning/burst, recover, hit, stagger, dead.
- Context selection: far uses Charge/Energy Burst; medium uses Pounce/Energy Burst; close uses Claw/Reposition. The last attack prevents direct repetition.
- Charge: 30 damage; 0.7 s telegraph; temporary super armor; 240 movement speed.
- Pounce: 28 damage; trajectory commits when launched; landing uses an independent impact area and FX.
- Claw Combo: two 22-damage active windows separated by 0.16 s, followed by 0.6 s recovery.
- Energy Burst: independent non-homing projectile, 25 damage, speed 155.
- Stagger: 110 damage accumulated inside a 1.4 s window causes 0.65 s stagger; no HUD bar yet.
- Death blocks actions, plays death plus `destroy_fx`, waits 0.85 s, awards XP, then emits `defeated` for the module reward hook.

## Shared combat rules

- A 260 ms shared melee slot prevents nearby regular melee units from starting in perfect synchronization.
- Lightweight horizontal separation prevents regular enemies occupying exactly the same position.
- Dangerous attacks use animation state, startup pauses and existing FX. Audio hooks are signals only: `enemy_attack`, `enemy_hit`, `enemy_death`, `armor_break`, `projectile_fire`, `projectile_hit`, `hound_charge`, `hound_pounce`, `hound_destroy`.
- FX never own hitboxes. All damage windows remain on `HitboxComponent` or `EnemyProjectile`.

## VLR-03 HOUND — Fase 2 (pase Zero)

- Al 50% de vida: rugido invulnerable de 1,1 s (sacudida, parpadeo rojo, mensaje "FASE 2"). La barra de jefe se tiñe de rojo.
- Cooldowns ×0,68, carga un 15% más rápida y umbral de stagger de 150.
- Patrones nuevos: **doble carga** (carga, derrape de 0,32 s, se gira y vuelve a cargar; castígala saltando por encima) y **abanico** (tres proyectiles: recto, ascendente y descendente).
- Todos los golpes hacen parpadear al HOUND en blanco.
