# Sprites runtime

`runtime/` contiene la reconstrucción provisional integrada en Godot: 22 atlas PNG, celdas de 64×64, orientación derecha, alfa real y pivote visual en `(32,63)`.

`source_reconstruction/` conserva las tiras de alta resolución generadas manualmente a partir de las tres láminas compartidas. No se cargan durante el juego.

Para regenerar los atlas normalizados:

```powershell
./tools/build_guandito_sprites.ps1
```

Esta reconstrucción sustituye al placeholder durante la validación, pero todavía debe considerarse arte provisional: los modelos generativos pueden introducir pequeñas variaciones entre frames. El concept art original permanece separado y no se utiliza directamente en runtime.
