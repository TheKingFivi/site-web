# 🎨 Frostline Checkpoint: original 3D models (made in Blender)

**What's here:**
- 14 props modeled in **Blender 5.2** specifically for this game, all original.
- Each has PBR textures: color, normal (surface depth), roughness and metalness.
- Textures are generated from scratch: painted metal with scratches and grime, brushed steel, rubber belt, woven fabric, wood, leaves, snow and pumpkin skin.

See `ALL_MODELS.png` for every model, and `previews/` for close-ups.

| Model | Triangles | Replaces in game |
|---|---|---|
| `XRayMachine` | 3,568 | X-ray conveyor at every lane (tunnel, lead curtains, belt, rollers, monitor) |
| `BodyScanner` | 2,076 | Walk-through scanner arch (glowing strips, footprint pad, console) |
| `Locker` | 1,708 | All hiding lockers (vents, handle, hinges) |
| `WaitingChairs` | 3,124 | Waiting-hall seat rows |
| `OfficeChair` | 2,356 | Officer swivel chairs |
| `OfficeDesk` | 2,128 | Officer desks (PC, keyboard, phone, mug, drawers) |
| `Stanchion` | 548 | Queue posts |
| `CoffeeMachine` | 1,116 | Break-room coffee machine |
| `VendingMachine` | 3,772 | Hall vending machine (25 cans behind glass) |
| `Plant` | 5,956 | Potted plants |
| `TrainCar` | 7,928 | The 3 night-train carriages (lit windows, doors, bogies) |
| `PineTree` | 836 | Snowy pine trees |
| `StreetLamp` | 2,992 | Lobby street lamps |
| `Pumpkin` | 7,286 | Carved jack-o'-lanterns (hollow, glowing inside) |

## Put them in the game (about 1 minute per model)

1. Open `FrostlineCheckpoint.rbxlx` in Roblox Studio.
2. **File → Import 3D** (or Avatar tab → Import 3D) and choose a file from `glb/`, for example `glb/XRayMachine.glb`.
   - Use the **.glb** files. They carry all 4 texture maps.
   - The `fbx/` folder has the same models if you prefer FBX.
3. In the import window, keep **Import textures** on, then click **Import**. Studio uploads the meshes and textures to *your* account. That's free, and it's the step I can't do for you.
4. The model appears in the Workspace. In the **Explorer**:
   - Make sure it's a **Model** named exactly like the file (for example `XRayMachine`).
   - **Drag it into ReplicatedStorage → ProModels.**
5. Repeat for the other models, then press **Play**. Every copy in every station and the lobby now uses the Blender model, sized and placed automatically, and the gameplay still works (lockers still hide you, the coffee still calms you, and so on).

**If something looks off:**
- **Faces the wrong way:** select the model in ProModels → Properties → **Attributes → +** → Number `Turn` = `180` (or 90 / 270).
- **Too small or too big:** add a Number attribute `Scale`, for example `1.15`.
- **No textures, plain grey:** in the import window, open the model's material settings and make sure textures are enabled. Or add a **SurfaceAppearance** to each MeshPart and pick the matching `_color`, `_normal`, `_roughness` and `_metalness` images.
- **Something glows too much or too little:** the glowing parts (screens, lamp bulbs, scanner strips, pumpkin candle) are separate MeshParts. Change their `Material` to **Neon** for a stronger glow, or to SmoothPlastic for less.

## Floor and wall textures (optional, even better)

`textures/` has 4 seamless texture sets for the station itself: `FloorTerrazzo`, `FloorTiles`, `WallPlaster` and `CarpetBlue`.

1. **View → Asset Manager → Images → Import** the `_color`, `_normal` and `_roughness` images.
2. In the Explorer: **MaterialService → + → MaterialVariant**.
   - Name it (for example `Terrazzo`).
   - Set **BaseMaterial = Concrete** (or Plaster for walls, Fabric for carpet).
   - Paste the image IDs into ColorMap, NormalMap and RoughnessMap. Set StudsPerTile to about 12.
3. In the MaterialService properties, set the Concrete override to `Terrazzo`. Every concrete floor in the game switches to it.

## Remaking or editing the models

`source/` has the Blender Python scripts that built everything:
- `texgen.py` makes the textures.
- `models.py` defines the 14 models.
- `lib.py` holds the modeling helpers.
- `build_all.py` exports the files and renders the previews.

With Blender installed: `pip install bpy`, then `python build_all.py --out out`. You can also open any `.glb` in Blender to edit it by hand.
