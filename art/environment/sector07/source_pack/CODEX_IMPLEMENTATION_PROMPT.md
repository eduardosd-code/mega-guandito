# CODEX — SECTOR 07 ART PASS 02 / ENVIRONMENT PACK

Use `Sector07_Environment_Pack_v1` as the environment source pack for the existing GUANDITO Godot 4.x project.

NON-NEGOTIABLE:
- Do not modify, regenerate, replace, recolor, resize, or reinterpret Guandito, Scrapper, Bulwark, Sentry, or HOUND.
- Preserve all existing gameplay, encounters, AI, combat timing, checkpoints, camera logic, and collision behavior unless a visual alignment bug requires a documented correction.
- Import pixel art with Filter OFF, Mipmaps OFF, nearest-neighbor.
- Base structural grid is 32×32.
- Never blind-slice a regional source atlas. Use only regions that are visually clean.
- `tiles/structure_32_grid.png` is the deterministic 32×32 grid source. Inspect every used cell before assigning it.
- Background parallax PNGs are intentionally opaque.
- For any source region whose background/edge is not technically clean, DO NOT degrade it with destructive keying. Keep the current placeholder and report `CLEAN_EXPORT_STILL_REQUIRED`.

WORK:
1. Inspect the repository and run Sector 07 before editing.
2. Read `manifest.json`.
3. Create/update the Sector 07 TileSet using 32×32 structural cells.
4. Keep gameplay collision simple and authored separately from visual pixels.
5. Create reusable Sprite2D/AnimatedSprite2D scenes for machinery, doors, terminals, checkpoint, fans, steam, sparks, drips, conveyors and environmental FX when clean regions exist.
6. Build parallax with `bg_far.png`, `bg_mid.png`, `bg_near.png`; add foreground only where it cannot obscure combat.
7. Apply the established zone identities:
   - Basement: dark, old maintenance, amber, steam.
   - First Contact: maintenance corridors/doors/terminals.
   - Pumping: large pipes/pumps, restrained teal.
   - Service Ducts: vents/cables/fans, tighter composition.
   - Assembly: machinery/conveyors, industrial orange.
   - Security/HOUND: cleaner dark metal, red security lighting.
   - Surface Exit: progressively colder exterior light.
8. Lime green remains scarce and is reserved mainly for Guandito, checkpoints, compatible systems, energy and rewards.
9. Do not create a final design for La Aguja.
10. Perform a complete playthrough and verify readability, collision, doors, checkpoints, secrets, combat arenas and performance.

DELIVER:
- Implemented assets
- TileSet/Terrain configuration
- Props/scenes created
- Animated environment
- Parallax setup
- Zone-by-zone art pass
- CLEAN_EXPORT_STILL_REQUIRED
- Collision changes
- Performance
- Files modified
- Screenshots of all seven zones
Then stop for manual validation.
