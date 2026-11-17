# Combat Lab

Open `res://scenes/levels/combat_lab.tscn` directly in Godot. It is an additional test scene; Sector 07 remains the project main scene.

## Controls

- F1: spawn Scrapper.
- F2: spawn Bulwark.
- F3: spawn Sentry.
- F4: spawn one HOUND (maximum one active).
- F5: spawn the mixed preset: two Scrappers, one Bulwark and one Sentry.
- F6: clear enemies and enemy projectiles without resetting Guandito.
- F7: heal Guandito.
- F8: toggle the existing hurtbox/hitbox debug renderer.
- F9: reset Combat Lab.

Combat controls remain A/D, Shift, Space, L, J, K and Q. Overdrive Evasion Mk-I is unlocked and equipped in this scene only.

## HUD

The temporary debug HUD reports player HP, regular enemy count and HOUND HP when present. It is not used by Sector 07.

## Presets

`EncounterData` stores role arrays and spawn offsets. The first preset is `resources/encounters/combat_lab_mixed.tres`. Future presets can use the same resource without adding spawn logic to Combat Lab.

## Balance workflow

Edit the `.tres` files under `resources/enemies/` rather than changing AI code. Principal variables include HP, XP, movement/detection/preferred ranges, damage, startup/recovery, cooldown, charge/projectile speed, alternate Sentry attack and Armor Break duration.

## Required scenarios

The automated `tests/phase7_combat_lab_smoke.gd` covers: one Scrapper; three Scrappers; one Sentry; Scrapper + Sentry; Bulwark Light/Heavy/Armor Break; Bulwark + two Scrappers; mixed preset; and HOUND contextual selection. Manual play remains required to judge telegraph readability, 2–3 minute HOUND pacing and multi-enemy fairness.
