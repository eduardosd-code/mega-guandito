# Sector 07 Environment Pack — integración

## Fuentes y criterio de uso

El paquete `Sector07_Environment_Pack_v1.zip` quedó preservado sin alteraciones en `art/environment/sector07/source_pack/`. Incluye atlas separados para estructura, tuberías, maquinaria, puertas, interactivos, animación, FX, decals, iluminación y tres fondos panorámicos. También se conserva la lámina maestra **1536×1024 RGBA** como referencia.

Se integró directamente todo recurso con límites suficientemente seguros. Los atlas cuyo fondo o separación no permite recortes limpios permanecen como referencia para evitar halos, rótulos o píxeles vecinos. No se modificaron sprites de personajes o enemigos.

Los elementos que solo existían dentro de la lámina compuesta se reconstruyeron en dos atlas transparentes de 1536×1024 bajo `art/environment/sector07/generated/`: `sector07_animated_fx_v1.png` y `sector07_foreground_decals_v1.png`. Ambos conservan el lenguaje visual de la referencia, pero son recursos nuevos del proyecto.

## TileSet

- Unidad: **32×32 px**.
- Recurso: `art/environment/sector07/tiles/Sector07TileSet.tres`.
- Atlas runtime: `sector07_structure.png`, copia de la cuadrícula técnica oficial de **16×11**.
- **176 tiles** registrados desde el atlas fuente.
- Terrain sets preparados: `FLOOR`, `WALL`, `PLATFORM`.
- Filtrado: nearest-neighbor por configuración global del proyecto; sin mipmaps.
- El TileMap es exclusivamente visual. Las colisiones limpias existentes siguen en cuerpos estáticos separados.

## Capas

Orden lógico creado dentro de `Sector07Environment`:

1. `ParallaxFar`
2. `ParallaxMid`
3. `BackgroundProps`
4. `GameplayTiles`
5. `GameplayProps`
6. `Interactive`
7. `Characters` — pertenece a la escena de nivel existente
8. `FX`
9. `Foreground`
10. `Lighting`

Far, Mid y Near usan los tres panoramas del paquete oficial. Far y Mid aplican desplazamientos suaves de 0.02 y 0.01 respecto a la cámara. Foreground usa pocos tubos/columnas semitransparentes y evita el centro de las arenas.

## Props reutilizables

- `IndustrialPump.tscn`
- `Generator.tscn`
- `LargeTank.tscn`
- `PipeCluster.tscn`
- `AssemblyMachine.tscn`
- `ControlStation.tscn`

Las variantes principales usan recortes de los atlas oficiales de maquinaria, tuberías e interactivos, con fallback procedural. Son decorativos, sin colisión ni lógica de gameplay.

## Ambiente animado

- `SteamVent`
- `IndustrialFan`
- `FlickeringLight`
- `SparkEmitter`
- `WaterDrip`
- `ConveyorBelt`
- `HangingCable`

Los siete usan frames del atlas reconstruido, con fallback procedural. Hay entre uno y tres focos de movimiento por pantalla. Los elementos fuera de un radio horizontal de 720 px permanecen ocultos y no actualizan su animación visual.

## Color por zona

- Sótano: carbón, óxido y ámbar apagado.
- Primer contacto: metal estructural y naranja moderado.
- Bombeo: carbón con teal controlado.
- Conductos: oliva oscuro, rejillas y cableado.
- Ensamblaje: naranja industrial y señalización puntual.
- Seguridad: metal oscuro y rojo.
- Superficie: azul frío y siluetas exteriores.

El verde lima se reserva para Guandito, checkpoints, energía e interactivos compatibles.

## Interactivos

Checkpoint, elevador y puertas usan recortes oficiales sin cambiar sus señales o comportamiento. Las puertas soportan estilos `maintenance`, `security` e `industrial`. Un material de corte alfa elimina el fondo tenue de las láminas sin filtrar los píxeles.

Foreground, señalización de peligro y decals visibles usan recortes transparentes de la reconstrucción nueva.

## Colisiones

No se modificó ninguna forma de piso, pared, plataforma, arena o personaje. El arte estructural se alinea sobre la parte superior de los rectángulos de colisión existentes. Props, decals, parallax y foreground no tienen colisión.
