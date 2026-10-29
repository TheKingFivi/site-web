"""Builds the 10 skins + the monster, renders previews, exports one GLB per owner."""
import sys
from pathlib import Path

import bpy  # noqa: I001  (must load before bmesh)
import bmesh
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).parent))
import characters as C  # noqa: E402
import lib  # noqa: E402

OUT = Path(sys.argv[sys.argv.index("--out") + 1])
ONLY = sys.argv[sys.argv.index("--only") + 1].split(",") if "--only" in sys.argv else None
SAMPLES = int(sys.argv[sys.argv.index("--samples") + 1]) if "--samples" in sys.argv else 32
(OUT / "glb").mkdir(parents=True, exist_ok=True)
(OUT / "previews").mkdir(parents=True, exist_ok=True)


def prepare(obj, repeat):
    lib.apply_modifiers(obj)
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    ngons = [f for f in bm.faces if len(f.verts) > 4]
    if ngons:
        bmesh.ops.triangulate(bm, faces=ngons)
    bm.to_mesh(obj.data)
    bm.free()
    lib.box_uv(obj, repeat)


def join(objs):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    j = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    return j


def finish_owner(owner, repeat=1.5):
    groups = {}
    for part, obj in owner.pieces:
        if obj.name not in bpy.data.objects:
            continue
        role = obj.get("role")
        prepare(obj, repeat)
        mat = obj.data.materials[0].name
        groups.setdefault((part, mat, role), []).append(obj)
    root = bpy.data.objects.new(owner.name, None)
    bpy.context.scene.collection.objects.link(root)
    count = {}
    tris = 0
    for (part, _mat, role), objs in groups.items():
        j = join(objs)
        count[part] = count.get(part, 0) + 1
        j.name = f"{owner.name}_{part}_{role}" if role else f"{owner.name}_{part}_{count[part]}"
        j.data.name = j.name
        # origin at the geometry centre (Roblox recentres MeshParts the same way)
        centre = sum((Vector(c) for c in j.bound_box), Vector()) / 8
        j.data.transform(__import__("mathutils").Matrix.Translation(-centre))
        j.location = j.location + centre
        j.parent = root
        tris += sum(len(p.vertices) - 2 for p in j.data.polygons)
    for a in C.anchors(owner.name, lib.material("PlasticDark")):
        lib.apply_modifiers(a)
        a.parent = root
    return root, tris, len(groups)


def render(path, front=True, target_z=-0.6, dist=12.5):
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = SAMPLES
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 700, 900
    scene.view_settings.view_transform = "AgX"
    scene.view_settings.look = "AgX - Medium High Contrast"
    world = bpy.data.worlds.new("W")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.05, 0.065, 0.11, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.7
    floor = lib.box("floor", (60, 60, 0.2), (0, 0, -4.02), lib.material("FloorTiles"), 0)
    lib.box_uv(floor, 6)
    for loc, energy in (((4, 8, 5), 900), ((-6, 4, 2), 350), ((0, -7, 6), 600)):
        light = bpy.data.lights.new("L", "AREA")
        light.energy = energy
        light.size = 4
        ob = bpy.data.objects.new("L", light)
        ob.location = loc
        ob.rotation_euler = (Vector((0, 0, 0)) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        scene.collection.objects.link(ob)
    cam = bpy.data.objects.new("Cam", bpy.data.cameras.new("Cam"))
    cam.data.lens = 50
    scene.collection.objects.link(cam)
    target = Vector((0, 0, target_z))
    cam.location = target + Vector((dist * 0.35, dist * (0.93 if front else -0.93), dist * 0.12))
    cam.rotation_euler = (target - cam.location).to_track_quat("-Z", "Y").to_euler()
    scene.camera = cam
    scene.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)


def export(root, path):
    bpy.ops.object.select_all(action="DESELECT")
    root.select_set(True)
    for c in root.children:
        c.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True, export_image_format="JPEG", export_jpeg_quality=88)


jobs = [("Skin" + k, (lambda k=k: C.build_uniform(k))) for k in C.SKINS] + [("Monster", C.build_monster), ("Civilian", C.build_civilian)]
for name, fn in jobs:
    if ONLY and name not in ONLY:
        continue
    lib.reset()
    C._plain.clear()
    owner = fn()
    root, tris, parts = finish_owner(owner)
    export(root, OUT / "glb" / f"{name}.glb")
    print(f"{name}: {parts} pieces, {tris} triangles", flush=True)
    if name == "Monster":
        # the monster replaces the body, so render it alone, scaled like in game
        root.scale = (1.45, 1.45, 1.45)
        root.location = (0, 0, 1.3)
    elif name == "Civilian":
        # preview: one hairstyle, tinted like a passenger
        import random

        rnd = random.Random(3)
        tints = {"Skin": (0.85, 0.62, 0.45), "Shirt": (0.2, 0.45, 0.25), "Pants": (0.2, 0.22, 0.3), "HairShort": (0.25, 0.15, 0.08)}
        for c in list(root.children):
            role = c.name.split("_")[-1]
            if role.startswith("Hair") and role != "HairShort":
                bpy.data.objects.remove(c, do_unlink=True)
                continue
            if role in tints and c.data.materials:
                m = c.data.materials[0].copy()
                m.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (*tints[role], 1)
                c.data.materials[0] = m
        _ = rnd
    if name == "Monster":
        render(OUT / "previews" / f"{name}.png", target_z=0.4, dist=17)
    else:
        render(OUT / "previews" / f"{name}.png")
