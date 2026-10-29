"""Tiny modeling toolkit on top of Blender's Python API (units: 1 Blender unit = 1 Roblox stud).
Convention: Z is up, the FRONT of every model faces -Y (it becomes -Z / LookVector in Roblox)."""
import math
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

TEX = Path(__file__).parent / "tex"
_materials = {}


def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _materials.clear()


def material(texset, tint=None, emission=None, emission_strength=0.0, alpha=1.0):
    """PBR material from a texture set in tex/ (TexName_color/normal/roughness/metalness.png)."""
    key = (texset, tint, emission, emission_strength, alpha)
    if key in _materials:
        return _materials[key]
    name = texset + ("_" + "".join(f"{int(c*255):02x}" for c in tint) if tint else "") + ("_glow" if emission else "")
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    out = nt.nodes["Material Output"]

    def img(kind, non_color):
        path = TEX / f"{texset}_{kind}.png"
        if not path.exists():
            return None
        node = nt.nodes.new("ShaderNodeTexImage")
        node.image = bpy.data.images.load(str(path), check_existing=True)
        if non_color:
            node.image.colorspace_settings.name = "Non-Color"
        return node

    col = img("color", False)
    if col:
        if tint:
            mix = nt.nodes.new("ShaderNodeMix")
            mix.data_type = "RGBA"
            mix.blend_type = "MULTIPLY"
            mix.inputs["Factor"].default_value = 1.0
            nt.links.new(col.outputs["Color"], mix.inputs["A"])
            mix.inputs["B"].default_value = (*tint, 1)
            nt.links.new(mix.outputs["Result"], bsdf.inputs["Base Color"])
        else:
            nt.links.new(col.outputs["Color"], bsdf.inputs["Base Color"])
    rough = img("roughness", True)
    if rough:
        nt.links.new(rough.outputs["Color"], bsdf.inputs["Roughness"])
    metal = img("metalness", True)
    if metal:
        nt.links.new(metal.outputs["Color"], bsdf.inputs["Metallic"])
    nrm = img("normal", True)
    if nrm:
        nm = nt.nodes.new("ShaderNodeNormalMap")
        nt.links.new(nrm.outputs["Color"], nm.inputs["Color"])
        nt.links.new(nm.outputs["Normal"], bsdf.inputs["Normal"])
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    if alpha < 1:
        bsdf.inputs["Alpha"].default_value = alpha
        bsdf.inputs["Transmission Weight"].default_value = 0.6
        bsdf.inputs["Roughness"].default_value = 0.05
        if rough:
            for link in list(nt.links):
                if link.to_socket == bsdf.inputs["Roughness"]:
                    nt.links.remove(link)
    _ = out
    _materials[key] = mat
    return mat


def _finish(obj, mat, bevel, segments):
    obj.data.materials.append(mat)
    if bevel > 0:
        mod = obj.modifiers.new("Bevel", "BEVEL")
        mod.width = bevel
        mod.segments = segments
        mod.limit_method = "ANGLE"
        mod.harden_normals = True
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def _new_object(name, mesh):
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def box(name, size, loc, mat, bevel=0.04, segments=2, rot=(0, 0, 0)):
    """Box of `size` (x,y,z) centred at `loc`."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
    bm.to_mesh(mesh)
    bm.free()
    obj = _new_object(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    return _finish(obj, mat, min(bevel, min(size) * 0.45), segments)


def cyl(name, radius, depth, loc, mat, axis="Z", verts=32, bevel=0.0, radius2=None, rot=None):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=verts, radius1=radius, radius2=radius if radius2 is None else radius2, depth=depth)
    bm.to_mesh(mesh)
    bm.free()
    obj = _new_object(name, mesh)
    obj.location = loc
    if rot is not None:
        obj.rotation_euler = rot
    elif axis == "X":
        obj.rotation_euler = (0, math.pi / 2, 0)
    elif axis == "Y":
        obj.rotation_euler = (math.pi / 2, 0, 0)
    return _finish(obj, mat, bevel, 2)


def sphere(name, radius, loc, mat, scale=(1, 1, 1), segments=32, rings=16):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=radius)
    bm.to_mesh(mesh)
    bm.free()
    obj = _new_object(name, mesh)
    obj.location = loc
    obj.scale = scale
    return _finish(obj, mat, 0, 0)


def torus(name, major, minor, loc, mat, rot=(0, 0, 0), major_seg=32, minor_seg=12):
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    for i in range(major_seg):
        a = 2 * math.pi * i / major_seg
        for j in range(minor_seg):
            b = 2 * math.pi * j / minor_seg
            r = major + minor * math.cos(b)
            bm.verts.new((r * math.cos(a), r * math.sin(a), minor * math.sin(b)))
    bm.verts.ensure_lookup_table()
    for i in range(major_seg):
        for j in range(minor_seg):
            a = i * minor_seg + j
            b = ((i + 1) % major_seg) * minor_seg + j
            c = ((i + 1) % major_seg) * minor_seg + (j + 1) % minor_seg
            d = i * minor_seg + (j + 1) % minor_seg
            bm.faces.new((bm.verts[a], bm.verts[b], bm.verts[c], bm.verts[d]))
    bm.to_mesh(mesh)
    bm.free()
    obj = _new_object(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    return _finish(obj, mat, 0, 0)


def lathe(name, profile, loc, mat, segments=32):
    """Revolve a list of (radius, z) points around Z."""
    mesh = bpy.data.meshes.new(name)
    bm = bmesh.new()
    rings = []
    for i in range(segments):
        a = 2 * math.pi * i / segments
        rings.append([bm.verts.new((r * math.cos(a), r * math.sin(a), z)) for r, z in profile])
    for i in range(segments):
        r1, r2 = rings[i], rings[(i + 1) % segments]
        for j in range(len(profile) - 1):
            bm.faces.new((r1[j], r2[j], r2[j + 1], r1[j + 1]))
    bm.to_mesh(mesh)
    bm.free()
    obj = _new_object(name, mesh)
    obj.location = loc
    return _finish(obj, mat, 0, 0)


def cut(target, cutter):
    """Boolean difference; the cutter is deleted."""
    mod = target.modifiers.new("Cut", "BOOLEAN")
    mod.operation = "DIFFERENCE"
    mod.object = cutter
    mod.solver = "EXACT"
    apply_modifiers(target)
    bpy.data.objects.remove(cutter, do_unlink=True)
    return target


def apply_modifiers(obj):
    depsgraph = bpy.context.evaluated_depsgraph_get()
    evaluated = obj.evaluated_get(depsgraph)
    mesh = bpy.data.meshes.new_from_object(evaluated)
    mats = list(obj.data.materials)
    obj.modifiers.clear()
    obj.data = mesh
    if not mesh.materials:
        for m in mats:
            mesh.materials.append(m)


def array(obj, count, offset):
    copies = [obj]
    for i in range(1, count):
        c = obj.copy()
        c.data = obj.data.copy()
        c.location = obj.location + Vector(offset) * i
        bpy.context.scene.collection.objects.link(c)
        copies.append(c)
    return copies


def box_uv(obj, repeat=4.0):
    """World-space box projection: the texture repeats every `repeat` studs on every face."""
    mesh = obj.data
    bm = bmesh.new()
    bm.from_mesh(mesh)
    uv = bm.loops.layers.uv.verify()
    mw = obj.matrix_world
    rot = mw.to_3x3()
    for face in bm.faces:
        n = (rot @ face.normal).normalized()
        ax = max(range(3), key=lambda i: abs(n[i]))
        for loop in face.loops:
            p = mw @ loop.vert.co
            if ax == 0:
                u, v = p.y, p.z
            elif ax == 1:
                u, v = p.x, p.z
            else:
                u, v = p.x, p.y
            loop[uv].uv = (u / repeat, v / repeat)
    bm.to_mesh(mesh)
    bm.free()


def finalize(name, objects, repeat=4.0):
    """Apply modifiers, UV, then join everything sharing a material into one mesh (one MeshPart each in Roblox)."""
    by_mat = {}
    for obj in objects:
        if obj.name not in bpy.data.objects:
            continue
        apply_modifiers(obj)
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        ngons = [f for f in bm.faces if len(f.verts) > 4]
        if ngons:
            bmesh.ops.triangulate(bm, faces=ngons)
        bm.to_mesh(obj.data)
        bm.free()
        box_uv(obj, repeat)
        mat = obj.data.materials[0] if obj.data.materials else None
        by_mat.setdefault(mat.name if mat else "none", []).append(obj)
    parts = []
    for mat_name, objs in by_mat.items():
        bpy.ops.object.select_all(action="DESELECT")
        for o in objs:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objs[0]
        if len(objs) > 1:
            bpy.ops.object.join()
        joined = bpy.context.view_layer.objects.active
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        joined.name = f"{name}_{mat_name}"
        joined.data.name = joined.name
        parts.append(joined)
    # Shared origin at the bottom centre of the whole model
    mins = Vector((1e9, 1e9, 1e9))
    maxs = Vector((-1e9, -1e9, -1e9))
    for p in parts:
        for corner in p.bound_box:
            w = p.matrix_world @ Vector(corner)
            mins = Vector(map(min, mins, w))
            maxs = Vector(map(max, maxs, w))
    base = Vector(((mins.x + maxs.x) / 2, (mins.y + maxs.y) / 2, mins.z))
    for p in parts:
        p.data.transform(Matrix.Translation(p.location - base))
        p.location = (0, 0, 0)
    tris = sum(sum(len(poly.vertices) - 2 for poly in p.data.polygons) for p in parts)
    return parts, tris, maxs - mins


def export_fbx(path, parts):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.ops.export_scene.fbx(
        filepath=str(path),
        use_selection=True,
        object_types={"MESH"},
        path_mode="COPY",
        embed_textures=True,
        axis_forward="-Z",
        axis_up="Y",
        apply_unit_scale=True,
        mesh_smooth_type="FACE",
        use_tspace=True,
    )


def export_glb(path, parts):
    bpy.ops.object.select_all(action="DESELECT")
    for p in parts:
        p.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(path), export_format="GLB", use_selection=True, export_yup=True, export_image_format="AUTO", export_apply=True)
