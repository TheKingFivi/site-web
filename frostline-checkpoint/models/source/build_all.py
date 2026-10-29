"""Builds every model, exports FBX for Roblox Studio, and renders a Cycles preview of each."""
import math
import sys
from pathlib import Path

import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
import lib  # noqa: E402
import models  # noqa: E402

OUT = Path(sys.argv[sys.argv.index("--out") + 1])
ONLY = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else None
SAMPLES = int(sys.argv[sys.argv.index("--samples") + 1]) if "--samples" in sys.argv else 48
(OUT / "fbx").mkdir(parents=True, exist_ok=True)
(OUT / "previews").mkdir(parents=True, exist_ok=True)


def setup_render(size):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 900, 900
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    bg = world.node_tree.nodes["Background"]
    bg.inputs["Color"].default_value = (0.05, 0.065, 0.11, 1)
    bg.inputs["Strength"].default_value = 0.6
    # studio floor
    floor = lib.box("floor", (400, 400, 0.2), (0, 0, -0.1), lib.material("FloorTiles"), 0)
    lib.box_uv(floor, 12)
    # key, fill, rim lights scaled to the model
    s = max(size)
    for loc, energy, col in (
        ((s * 0.9, -s * 1.3, s * 1.4), 2200, (1.0, 0.95, 0.88)),
        ((-s * 1.4, -s * 0.5, s * 0.8), 700, (0.75, 0.85, 1.0)),
        ((0, s * 1.5, s * 1.2), 1300, (0.8, 0.9, 1.0)),
    ):
        light = bpy.data.lights.new("L", "AREA")
        light.energy = energy * (s / 10) ** 2
        light.size = s * 0.8
        light.color = col
        obj = bpy.data.objects.new("L", light)
        obj.location = loc
        direction = Vector((0, 0, size[2] * 0.4)) - Vector(loc)
        obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(obj)
    cam_data = bpy.data.cameras.new("Cam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("Cam", cam_data)
    scene.collection.objects.link(cam)
    target = Vector((0, 0, size[2] * 0.45))
    dist = s * 2.1
    cam.location = target + Vector((dist * 0.62, -dist * 0.78, dist * 0.42))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam


report = []
for name, (fn, repeat) in models.MODELS.items():
    if ONLY and name not in ONLY:
        continue
    lib.reset()
    models.mats()
    objs = fn()
    parts, tris, size = lib.finalize(name, objs, repeat)
    lib.export_fbx(OUT / "fbx" / f"{name}.fbx", parts)
    (OUT / "glb").mkdir(exist_ok=True)
    lib.export_glb(OUT / "glb" / f"{name}.glb", parts)
    report.append(f"{name}: {len(parts)} mesh parts, {tris} triangles, size {size.x:.1f} x {size.y:.1f} x {size.z:.1f} studs")
    print(report[-1], flush=True)
    setup_render(size)
    bpy.context.scene.render.filepath = str(OUT / "previews" / f"{name}.png")
    bpy.ops.render.render(write_still=True)

(OUT / "report.txt").write_text("\n".join(report) + "\n")
