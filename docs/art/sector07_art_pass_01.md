# Sector 07 — Art Pass 01

Fecha: 2026-08-26

## Implementado

- Paquete fuente completo preservado en `art/environment/sector07/source_pack/`.
- Atlas estructural oficial 32×32 con sus 176 celdas registradas en `Sector07TileSet.tres`.
- Capas Far/Mid/Background/Gameplay/Interactive/FX/Foreground/Lighting.
- Seis props industriales reutilizables con recortes oficiales y fallback procedural.
- Siete elementos ambientales animados reutilizables.
- Paleta y overlay diferenciados para las siete zonas.
- Checkpoint, elevador y tres estilos de puerta integrados desde los atlas oficiales.
- Art pass específico de bombeo, ensamblaje, seguridad/HOUND y salida.
- Tres panoramas oficiales Far/Mid/Near y placeholder abstracto de La Aguja.
- Culling visual por distancia para ambiente animado.
- Dos atlas transparentes reconstruidos para animación/FX y foreground/decals.
- Fans, luces, pantallas, pistones, conveyor, vapor, chispas, gotas, cables, partículas, señalización y piezas de foreground disponibles sin el fondo de la lámina.

## Capturas de validación

Se generaron en `artifacts/sector07_art_pass/`:

- `01_awakening.png`
- `02_first_contact.png`
- `03_pumping.png`
- `04_service_ducts.png`
- `05_assembly.png`
- `06_hound_arena.png`
- `07_surface_exit.png`

Las siete comparten materiales y estructura, pero cambian acento, densidad y props. Guandito, Scrapper, Sentry, Bulwark y HOUND mantienen contraste claro contra el fondo.

## ART_REQUIRES_CLEAN_EXPORT

El environment pack ya no tiene bloqueos de exportación limpia: los recursos seguros se integraron desde el paquete y los elementos atrapados en la lámina se reconstruyeron con transparencia real.

Pendiente únicamente por dirección de arte, no por exportación:

- diseño final aprobado de KORA;
- diseño final aprobado de La Aguja.

Si más adelante se entregan fuentes pixel-perfect originales, podrán sustituir los atlas reconstruidos sin cambiar gameplay ni colisiones.

## Placeholders restantes

- Las animaciones ambientales y el foreground usan atlas reconstruidos; conservan fallback procedural.
- La geometría modular usa la cuadrícula técnica oficial del paquete.
- KORA y La Aguja son siluetas provisionales.
- Iluminación está representada mediante color y emissive visual; no se añadieron luces 2D grandes.
- Audio ambiental conserva los hooks existentes.

## Validación y performance

- `sector07_smoke`: PASS, incluyendo la carga de los 176 tiles fuente.
- Layout, encounters, AI, daño, HP, XP y movimiento no fueron alterados.
- Los FX ambientales lejanos se ocultan fuera de 720 px.
- Se mantienen menos de tres movimientos ambientales dominantes por pantalla.
- No se detectaron plataformas invisibles ni errores de parseo después de integrar las capas.
- Godot headless mantiene los avisos conocidos de log/certificados y una advertencia de ObjectDB al cerrar ciertos tests; no provienen del art pass.
