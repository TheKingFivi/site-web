"""Officer skins and the monster, modelled piece by piece on Roblox's R15 body parts.

Reference body (Roblox R15 default sizes), coordinates relative to the UpperTorso centre, in Roblox axes
(x right, y up, z back). In Blender that is (x, -z, y): Roblox up = Blender +Z and the FRONT of the
character faces Blender +Y (Roblox -Z after the anchor frame is applied in game).

Every piece is named  <Owner>_<BodyPart>_<n>  and three anchors  <Owner>_AnchorA/B/C  mark the
reference frame: A = origin, B = 10 studs up, C = 10 studs along +X. The game uses them to undo any
scale/rotation the Roblox importer applies, then welds each piece to the matching body part."""
import math

from lib import box, cut, cyl, lathe, material, sphere, torus

R15 = {
    "Head": ((0, 1.45, 0), (1.2, 1.2, 1.2)),
    "UpperTorso": ((0, 0, 0), (2, 1.6, 1)),
    "LowerTorso": ((0, -1.0, 0), (2, 0.4, 1)),
    "LeftUpperArm": ((-1.5, 0.215, 0), (1, 1.17, 1)),
    "RightUpperArm": ((1.5, 0.215, 0), (1, 1.17, 1)),
    "LeftLowerArm": ((-1.5, -0.895, 0), (1, 1.05, 1)),
    "RightLowerArm": ((1.5, -0.895, 0), (1, 1.05, 1)),
    "LeftHand": ((-1.5, -1.57, 0), (1, 0.3, 1)),
    "RightHand": ((1.5, -1.57, 0), (1, 0.3, 1)),
    "LeftUpperLeg": ((-0.5, -1.81, 0), (1, 1.215, 1)),
    "RightUpperLeg": ((0.5, -1.81, 0), (1, 1.215, 1)),
    "LeftLowerLeg": ((-0.5, -3.02, 0), (1, 1.2, 1)),
    "RightLowerLeg": ((0.5, -3.02, 0), (1, 1.2, 1)),
    "LeftFoot": ((-0.5, -3.77, 0), (1, 0.3, 1)),
    "RightFoot": ((0.5, -3.77, 0), (1, 0.3, 1)),
}


def B(part, dx=0.0, dy=0.0, dz=0.0):
    """Blender location for an offset (Roblox axes: dx right, dy up, dz FORWARD) from a body part centre."""
    (x, y, z), _ = R15[part]
    return (x + dx, dz, y + dy)


class Owner:
    """Collects pieces per body part; each piece keeps its own material (one MeshPart each in Roblox)."""

    def __init__(self, name):
        self.name = name
        self.pieces = []  # (bodypart, object)

    def add(self, part, obj, role=None):
        self.pieces.append((part, obj))
        if role:
            obj["role"] = role
        return obj


def anchors(owner, mat):
    out = []
    for suffix, loc in (("AnchorA", (0, 0, 0)), ("AnchorB", (0, 0, 10)), ("AnchorC", (10, 0, 0))):
        a = box(f"{owner}_{suffix}", (0.1, 0.1, 0.1), loc, mat, 0)
        out.append(a)
    return out


# ---------------- SKINS ----------------
SKINS = {
    "Standard": "Cap",
    "Night": "Cap",
    "Arctic": "Ushanka",
    "Crimson": "Peaked",
    "Gold": "Peaked",
    "Plague": "PlagueMask",
    "Pumpkin": "Pumpkin",
    "Witch": "Witch",
    "Count": "Fangs",
    "Wraith": "Hood",
}


def coat(o, coat_m, trim_m, dark_m, metal_m, long_coat=False):
    """Officer coat: torso shell, collar, lapels, buttons, badge, epaulettes, belt, skirt, sleeves, cuffs."""
    o.add("UpperTorso", box("coat", (2.14, 1.12, 1.66), B("UpperTorso", 0, 0.01, 0), coat_m, 0.18, 3))
    o.add("UpperTorso", box("collar", (1.2, 1.0, 0.28), B("UpperTorso", 0, 0.82, -0.05), coat_m, 0.12, 2))
    for side in (-1, 1):
        lapel = box("lapel", (0.32, 0.06, 0.8), B("UpperTorso", side * 0.28, 0.42, 0.57), coat_m, 0.03)
        lapel.rotation_euler = (0, side * -0.32, 0)
        o.add("UpperTorso", lapel)
        o.add("UpperTorso", box("epaulette", (0.62, 0.7, 0.1), B("UpperTorso", side * 0.78, 0.82, 0), trim_m, 0.04))
    for i in range(4):
        o.add("UpperTorso", cyl("button", 0.07, 0.05, B("UpperTorso", 0.18, 0.35 - i * 0.32, 0.58), metal_m, axis="Y", verts=12))
    badge = lathe("badge", [(0, 0), (0.16, 0), (0.18, 0.03), (0.12, 0.05), (0, 0.05)], B("UpperTorso", -0.5, 0.25, 0.56), metal_m, 16)
    badge.rotation_euler = (-math.pi / 2, 0, 0)
    o.add("UpperTorso", badge)
    o.add("UpperTorso", box("pocket", (0.5, 0.05, 0.35), B("UpperTorso", 0.55, 0.2, 0.57), coat_m, 0.02))
    o.add("LowerTorso", box("belt", (2.18, 1.14, 0.3), B("LowerTorso", 0, 0.05, 0), dark_m, 0.06))
    o.add("LowerTorso", box("buckle", (0.36, 0.06, 0.26), B("LowerTorso", 0, 0.05, 0.58), metal_m, 0.03))
    skirt = 1.3 if long_coat else 0.55
    for side in (-1, 1):
        flap = box("skirt", (1.0, 1.1, skirt), B("LowerTorso", side * 0.52, -skirt / 2 - 0.05, 0), coat_m, 0.1)
        o.add("LowerTorso", flap)
    for side, name in ((-1, "Left"), (1, "Right")):
        o.add(f"{name}UpperArm", box("sleeve", (1.1, 1.1, 1.2), B(f"{name}UpperArm"), coat_m, 0.2, 3))
        o.add(f"{name}LowerArm", box("sleeve", (1.06, 1.06, 1.08), B(f"{name}LowerArm"), coat_m, 0.2, 3))
        o.add(f"{name}LowerArm", box("cuff", (1.12, 1.12, 0.18), B(f"{name}LowerArm", 0, -0.42, 0), trim_m, 0.06))
        o.add(f"{name}UpperArm", box("stripe", (0.06, 0.5, 0.9), B(f"{name}UpperArm", side * 0.56, 0, 0), trim_m, 0.02))


def hat(o, kind, coat_m, trim_m, dark_m, metal_m, M):
    H = "Head"
    if kind in ("Cap", "Peaked"):
        crown = 0.62 if kind == "Peaked" else 0.45
        o.add(H, lathe("crown", [(0, 0.0), (0.66, 0.0), (0.7, 0.12), (0.78 if kind == "Peaked" else 0.68, crown), (0, crown)], B(H, 0, 0.36, 0), coat_m, 32))
        o.add(H, torus("band", 0.68, 0.07, B(H, 0, 0.42, 0), dark_m))
        visor = cyl("visor", 0.55, 0.05, B(H, 0, 0.38, 0.55), dark_m, verts=24)
        visor.scale = (1, 0.7, 1)
        visor.rotation_euler = (-0.18, 0, 0)
        o.add(H, visor)
        badge = lathe("capbadge", [(0, 0), (0.16, 0), (0.18, 0.04), (0, 0.06)], B(H, 0, 0.58, 0.66), metal_m, 6)
        badge.rotation_euler = (-math.pi / 2, 0, 0)
        o.add(H, badge)
        if kind == "Peaked":
            o.add(H, torus("cord", 0.62, 0.035, B(H, 0, 0.48, 0.05), trim_m))
    elif kind == "Ushanka":
        o.add(H, sphere("fur", 0.78, B(H, 0, 0.42, 0), M["fur"], scale=(1, 1, 0.6), segments=32, rings=16))
        o.add(H, box("flap", (1.6, 0.25, 0.4), B(H, 0, 0.56, 0.55), M["fur"], 0.15))
        for side in (-1, 1):
            o.add(H, box("ear", (0.22, 0.9, 0.95), B(H, side * 0.7, -0.1, -0.05), M["fur"], 0.1))
        badge = lathe("starbadge", [(0, 0), (0.2, 0), (0, 0.05)], B(H, 0, 0.6, 0.7), metal_m, 5)
        badge.rotation_euler = (-math.pi / 2, 0, 0)
        o.add(H, badge)
    elif kind == "PlagueMask":
        o.add(H, sphere("mask", 0.66, B(H), M["leather"], scale=(1, 1, 1.02), segments=32, rings=16))
        beak = lathe("beak", [(0.36, 0), (0.3, 0.4), (0.18, 0.9), (0.05, 1.3), (0, 1.38)], B(H, 0, -0.15, 0.55), M["leather"], 24)
        beak.rotation_euler = (-math.pi / 2 - 0.35, 0, 0)
        o.add(H, beak)
        for side in (-1, 1):
            o.add(H, torus("goggle", 0.16, 0.05, B(H, side * 0.26, 0.12, 0.6), metal_m, rot=(math.pi / 2, 0, 0)))
            o.add(H, cyl("lens", 0.15, 0.04, B(H, side * 0.26, 0.12, 0.61), M["glass"], axis="Y", verts=20))
        o.add(H, cyl("brim", 1.25, 0.06, B(H, 0, 0.62, 0), coat_m, verts=40))
        o.add(H, cyl("tophat", 0.62, 0.7, B(H, 0, 1.0, 0), coat_m, verts=32, radius2=0.66))
        o.add(H, torus("hatband", 0.64, 0.05, B(H, 0, 0.72, 0), trim_m))
    elif kind == "Pumpkin":
        for i in range(10):
            a = i * 2 * math.pi / 10
            lobe = sphere("lobe", 0.62, B(H, math.cos(a) * 0.32, 0.05, math.sin(a) * 0.32), M["pumpkin"], scale=(0.75, 0.75, 0.95), segments=16, rings=10)
            lobe.rotation_euler = (0, 0, a)
            o.add(H, lobe)
        for x in (-0.28, 0.28):
            o.add(H, cyl("eye", 0.17, 0.12, B(H, x, 0.2, 0.78), M["orangeglow"], verts=3, rot=(-math.pi / 2, 0, 0)))
        o.add(H, box("mouth", (0.7, 0.1, 0.16), B(H, 0, -0.22, 0.78), M["orangeglow"], 0.04))
        o.add(H, cyl("stem", 0.1, 0.4, B(H, 0, 0.82, 0), M["bark"], verts=10, radius2=0.07))
    elif kind == "Witch":
        o.add(H, cyl("brim", 1.4, 0.06, B(H, 0, 0.45, 0), coat_m, verts=48))
        profile = [(0.7, 0), (0.6, 0.5), (0.45, 1.0), (0.28, 1.5), (0.12, 1.9), (0, 2.1)]
        cone = lathe("cone", profile, B(H, 0, 0.45, 0), coat_m, 32)
        cone.rotation_euler = (-0.18, 0, 0)
        o.add(H, cone)
        o.add(H, torus("band", 0.66, 0.07, B(H, 0, 0.56, 0), trim_m))
        o.add(H, box("buckle", (0.3, 0.06, 0.24), B(H, 0, 0.56, 0.68), metal_m, 0.03))
    elif kind == "Fangs":
        o.add(H, sphere("hair", 0.66, B(H, 0, 0.2, -0.05), dark_m, scale=(1, 1, 0.7), segments=24, rings=12))
        widow = cyl("peak", 0.18, 0.2, B(H, 0, 0.32, 0.6), dark_m, verts=3, rot=(-math.pi / 2, 0, math.pi))
        o.add(H, widow)
        for x in (-0.14, 0.14):
            o.add(H, cyl("fang", 0.045, 0.16, B(H, x, -0.38, 0.6), M["bone"], verts=8, radius2=0.0, rot=(math.pi, 0, 0)))
        collar = box("highcollar", (2.3, 0.15, 1.4), B("UpperTorso", 0, 1.15, -0.45), trim_m, 0.05)
        collar.rotation_euler = (0.35, 0, 0)
        o.add("UpperTorso", collar)
        o.add("UpperTorso", box("cape", (2.2, 0.12, 3.4), B("UpperTorso", 0, -0.9, -0.62), coat_m, 0.05))
    elif kind == "Hood":
        hood = sphere("hood", 0.82, B(H, 0, 0.1, -0.08), coat_m, scale=(1, 1.05, 1.1), segments=32, rings=16)
        cut(hood, sphere("opening", 0.6, B(H, 0, 0.0, 0.7), coat_m, scale=(1, 0.8, 1.1)))
        o.add(H, hood)
        o.add(H, sphere("void", 0.58, B(H, 0, 0.0, 0.05), M["voidblack"], segments=24, rings=12))
        for x in (-0.2, 0.2):
            o.add(H, sphere("eye", 0.09, B(H, x, 0.05, 0.55), M["cyanglow"], scale=(1.4, 0.5, 0.8), segments=12, rings=8))
        for i in range(5):
            shard = cyl("ice", 0.12, 0.7, B(H, -0.6 + i * 0.3, 0.75 + (i % 2) * 0.1, -0.1), M["ice"], verts=5, radius2=0.0)
            shard.rotation_euler = (0.2, (i - 2) * 0.25, 0)
            o.add(H, shard)


def build_skin(key):
    o = Owner("Skin" + key)
    coat_m = material(f"Coat{key}")
    trim_m = material(f"Trim{key}")
    M = {
        "fur": material("Fur"),
        "leather": material("Leather"),
        "pumpkin": material("Pumpkin"),
        "bark": material("Bark"),
        "bone": material("Bone"),
        "glass": material("PlasticWhite", tint=(0.6, 0.8, 0.95), alpha=0.4),
        "orangeglow": material("PlasticWhite", emission=(1.0, 0.55, 0.1), emission_strength=5.0),
        "cyanglow": material("PlasticWhite", emission=(0.4, 0.9, 1.0), emission_strength=6.0),
        "voidblack": material("PlasticDark", tint=(0.05, 0.05, 0.08)),
        "ice": material("PlasticWhite", tint=(0.7, 0.9, 1.0), alpha=0.6),
    }
    dark_m = material("Leather")
    metal_m = material("Steel")
    coat(o, coat_m, trim_m, dark_m, metal_m, long_coat=key in ("Plague", "Witch", "Count", "Wraith", "Crimson", "Gold"))
    hat(o, SKINS[key], coat_m, trim_m, dark_m, metal_m, M)
    return o


# ---------------- MONSTER ----------------
def build_monster():
    o = Owner("Monster")
    skin = material("MonsterSkin")
    bone = material("Bone")
    eye = material("PlasticWhite", emission=(1.0, 1.0, 1.0), emission_strength=8.0)
    mouth = material("PlasticDark", tint=(0.25, 0.0, 0.02))
    H = "Head"
    # Long skull: stretched head, sunken eyes, huge jaw
    o.add(H, sphere("skull", 0.62, B(H, 0, 0.12, -0.05), skin, scale=(0.85, 1.0, 1.25), segments=32, rings=20))
    o.add(H, sphere("jaw", 0.5, B(H, 0, -0.38, 0.12), skin, scale=(0.82, 0.9, 0.6), segments=24, rings=14))
    for x in (-0.22, 0.22):
        o.add(H, sphere("socket", 0.17, B(H, x, 0.12, 0.43), mouth, scale=(1, 0.5, 1.2), segments=16, rings=10))
        o.add(H, sphere("eye", 0.08, B(H, x, 0.12, 0.5), eye, scale=(1, 0.5, 1.3), segments=12, rings=8))
    o.add(H, box("maw", (0.72, 0.2, 0.34), B(H, 0, -0.3, 0.48), mouth, 0.08))
    for i in range(9):
        x = -0.32 + i * 0.08
        o.add(H, cyl("toothU", 0.03, 0.17, B(H, x, -0.19, 0.55), bone, verts=6, radius2=0.0, rot=(math.pi, 0, 0)))
        o.add(H, cyl("toothL", 0.03, 0.15, B(H, x + 0.04, -0.42, 0.55), bone, verts=6, radius2=0.0))
    # Torso: emaciated ribcage, spine spikes
    o.add("UpperTorso", sphere("chest", 0.5, B("UpperTorso", 0, 0.05, 0), skin, scale=(1.55, 0.85, 1.75), segments=28, rings=16))
    o.add("UpperTorso", sphere("belly", 0.5, B("UpperTorso", 0, -0.6, 0), skin, scale=(1.0, 0.6, 0.9), segments=20, rings=12))
    for i in range(5):
        y = 0.45 - i * 0.24
        rib = torus("rib", 0.7, 0.045, B("UpperTorso", 0, y, 0.05), bone, rot=(math.pi / 2, 0, 0))
        rib.scale = (1.05, 0.55, 1)
        o.add("UpperTorso", rib)
    for i in range(6):
        spike = cyl("spine", 0.1, 0.5, B("UpperTorso", 0, 0.6 - i * 0.28, -0.48), bone, verts=6, radius2=0.0)
        spike.rotation_euler = (-1.9, 0, 0)
        o.add("UpperTorso", spike)
    for side in (-1, 1):
        o.add("UpperTorso", sphere("shoulder", 0.42, B("UpperTorso", side * 0.88, 0.55, 0), skin, segments=16, rings=10))
    o.add("LowerTorso", sphere("pelvis", 0.5, B("LowerTorso"), skin, scale=(1.4, 0.7, 0.7), segments=20, rings=12))
    o.add("LowerTorso", torus("hips", 0.5, 0.07, B("LowerTorso", 0, 0, 0), bone, rot=(math.pi / 2, 0, 0)))
    # Limbs: thin, bony, too long; knobbly joints; claws
    for side, name in ((-1, "Left"), (1, "Right")):
        o.add(f"{name}UpperArm", cyl("bicep", 0.24, 1.4, B(f"{name}UpperArm", 0, -0.1, 0), skin, verts=16, radius2=0.18))
        o.add(f"{name}LowerArm", cyl("forearm", 0.2, 1.4, B(f"{name}LowerArm", 0, -0.15, 0), skin, verts=16, radius2=0.14))
        o.add(f"{name}LowerArm", sphere("elbow", 0.22, B(f"{name}LowerArm", 0, 0.5, -0.05), bone, segments=12, rings=8))
        o.add(f"{name}Hand", box("palm", (0.5, 0.35, 0.5), B(f"{name}Hand", 0, -0.05, 0), skin, 0.1))
        for k in range(4):
            claw = cyl("claw", 0.05, 0.9, B(f"{name}Hand", -0.18 + k * 0.12, -0.6, 0.1), bone, verts=6, radius2=0.0, rot=(math.pi + 0.25, 0, 0))
            o.add(f"{name}Hand", claw)
        o.add(f"{name}UpperLeg", cyl("thigh", 0.28, 1.4, B(f"{name}UpperLeg", 0, -0.05, 0), skin, verts=16, radius2=0.2))
        o.add(f"{name}LowerLeg", cyl("shin", 0.2, 1.4, B(f"{name}LowerLeg", 0, -0.05, 0), skin, verts=16, radius2=0.14))
        o.add(f"{name}LowerLeg", sphere("knee", 0.24, B(f"{name}LowerLeg", 0, 0.55, 0.06), bone, segments=12, rings=8))
        o.add(f"{name}Foot", box("foot", (0.55, 1.1, 0.25), B(f"{name}Foot", 0, -0.05, 0.25), skin, 0.1))
        for k in range(3):
            o.add(f"{name}Foot", cyl("toeclaw", 0.06, 0.5, B(f"{name}Foot", -0.15 + k * 0.15, -0.1, 0.9), bone, verts=6, radius2=0.0, rot=(-math.pi / 2 + 0.3, 0, 0)))
    return o


def mannequin():
    """Grey reference body for preview renders only (not exported)."""
    m = material("PlasticWhite", tint=(0.62, 0.64, 0.7))
    out = []
    for part, (_, size) in R15.items():
        if part == "Head":
            out.append(sphere("head", 0.62, B(part), material("SkinTone"), segments=32, rings=16))
        else:
            out.append(box(part, (size[0] * 0.98, size[2] * 0.98, size[1] * 0.98), B(part), m, 0.12))
    return out


# ---------------- SMOOTH HUMAN BODY (replaces the blocky Roblox body) ----------------
import bpy  # noqa: E402


def plain(name, rgb, rough=0.55, metal=0.0, emission=None, strength=0.0):
    """Untextured material: Roblox can tint these MeshParts with .Color (used for passengers)."""
    key = ("plain", name)
    if key in _plain:
        return _plain[key]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*rgb, 1)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    if emission:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1)
        bsdf.inputs["Emission Strength"].default_value = strength
    _plain[key] = mat
    return mat


_plain = {}


def capsule(name, radius, length, loc, mat, radius_bottom=None, segments=16):
    """Vertical rounded limb: tapered tube with ball ends."""
    rb = radius if radius_bottom is None else radius_bottom
    prof = []
    steps = 6
    for i in range(steps + 1):  # bottom cap
        a = -math.pi / 2 + (math.pi / 2) * i / steps
        prof.append((rb * math.cos(a), -length / 2 + rb * math.sin(a) + 0.0))
    for i in range(steps + 1):  # top cap
        a = (math.pi / 2) * i / steps
        prof.append((radius * math.cos(a), length / 2 + radius * math.sin(a)))
    prof = [(max(r, 0.0), z) for r, z in prof]
    return lathe(name, prof, loc, mat, segments)


def ellipsoid(name, r, scale, loc, mat, seg=20, rings=12):
    return sphere(name, r, loc, mat, scale=scale, segments=seg, rings=rings)


def human_body(o, skin, shirt, pants, shoes, face=True, eye_white=None, iris=None, lip=None, roles=False):
    """Smooth human body on the R15 parts. With roles=True the piece suffix names its colour role."""
    tag = (lambda r: r) if roles else (lambda r: None)
    H = "Head"
    # Cartoon head: big and round, sitting on a short neck
    o.add(H, ellipsoid("head", 0.84, (0.98, 0.94, 0.98), B(H, 0, 0.24, 0), skin, 28, 18), tag("Skin"))
    o.add("UpperTorso", capsule("neck", 0.24, 0.3, B("UpperTorso", 0, 0.82, 0), skin), tag("Skin"))
    for side in (-1, 1):
        o.add(H, ellipsoid("ear", 0.18, (0.45, 0.75, 1.0), B(H, side * 0.81, 0.18, -0.02), skin, 12, 8), tag("Skin"))
    if face:
        ew = eye_white or plain("EyeWhite", (0.97, 0.97, 0.97), 0.25)
        ir = iris or plain("Iris", (0.04, 0.04, 0.05), 0.15)
        shine = plain("Shine", (1, 1, 1), 0.1, emission=(1, 1, 1), strength=1.5)
        for side in (-1, 1):
            # Big white eye, dark pupil, little shine (the "cartoon" look)
            o.add(H, ellipsoid("eyewhite", 0.27, (0.88, 0.4, 1.12), B(H, side * 0.29, 0.3, 0.62), ew, 18, 12), tag("Eyes"))
            o.add(H, ellipsoid("iris", 0.13, (1.0, 0.4, 1.1), B(H, side * 0.27, 0.26, 0.71), ir, 14, 10), tag("Iris"))
            o.add(H, sphere("shine", 0.045, B(H, side * 0.24, 0.33, 0.77), shine, segments=8, rings=6), tag("Eyes"))
            brow = box("brow", (0.34, 0.08, 0.09), B(H, side * 0.29, 0.66, 0.62), ir, 0.03)
            brow.rotation_euler = (0, side * 0.14, 0)
            o.add(H, brow, tag("Iris"))
        o.add(H, ellipsoid("nose", 0.1, (0.85, 0.8, 1.0), B(H, 0, 0.04, 0.8), skin, 12, 8), tag("Skin"))
        smile = torus("smile", 0.19, 0.035, B(H, 0, -0.16, 0.7), lip or plain("Lip", (0.25, 0.08, 0.08), 0.4), rot=(math.pi / 2, 0, 0))
        cut(smile, box("cutter", (0.7, 0.7, 0.45), B(H, 0, 0.06, 0.7), ir, 0))
        o.add(H, smile, tag("Lip"))
    # Torso: chest, waist, shoulders (shirt)
    o.add("UpperTorso", lathe("torso", [(0.0, -0.8), (0.62, -0.8), (0.7, -0.35), (0.82, 0.25), (0.78, 0.62), (0.45, 0.82), (0.0, 0.84)], B("UpperTorso"), shirt, 22), tag("Shirt"))
    o.pieces[-1][1].scale = (1.0, 0.62, 1.0)
    for side in (-1, 1):
        o.add("UpperTorso", ellipsoid("shoulder", 0.31, (1.0, 0.95, 0.85), B("UpperTorso", side * 0.68, 0.5, 0), shirt, 14, 10), tag("Shirt"))
    o.add("LowerTorso", ellipsoid("hips", 0.5, (1.4, 0.82, 0.62), B("LowerTorso", 0, 0.02, 0), pants, 24, 14), tag("Pants"))
    # Arms (pulled in toward the body; R15 swings them around the shoulder)
    for side, name in ((-1, "Left"), (1, "Right")):
        inward = -side * 0.32
        o.add(f"{name}UpperArm", capsule("upperarm", 0.3, 0.95, B(f"{name}UpperArm", inward, 0.0, 0), shirt, 0.27), tag("Shirt"))
        o.add(f"{name}LowerArm", capsule("forearm", 0.27, 0.88, B(f"{name}LowerArm", inward, 0.0, 0), shirt, 0.22), tag("Shirt"))
        o.add(f"{name}Hand", ellipsoid("palm", 0.22, (0.9, 0.6, 1.15), B(f"{name}Hand", inward, -0.05, 0), skin, 14, 10), tag("Skin"))
        thumb = capsule("thumb", 0.07, 0.18, B(f"{name}Hand", inward - side * -0.16, 0.0, 0.12), skin, segments=10)
        thumb.rotation_euler = (0.4, side * 0.5, 0)
        o.add(f"{name}Hand", thumb, tag("Skin"))
        # Legs (trousers) and shoes
        o.add(f"{name}UpperLeg", capsule("thigh", 0.4, 0.98, B(f"{name}UpperLeg", 0, 0.02, 0), pants, 0.34), tag("Pants"))
        o.add(f"{name}LowerLeg", capsule("shin", 0.34, 0.98, B(f"{name}LowerLeg", 0, 0.05, 0), pants, 0.28), tag("Pants"))
        o.add(f"{name}Foot", ellipsoid("shoe", 0.32, (0.95, 1.6, 0.6), B(f"{name}Foot", 0, -0.02, 0.18), shoes, 18, 12), tag("Shoes"))


def build_uniform(key):
    """Officer skin = smooth body + fitted uniform details (hat/mask from hat())."""
    o = Owner("Skin" + key)
    coat_m = material(f"Coat{key}")
    trim_m = material(f"Trim{key}")
    dark_m = material("Leather")
    metal_m = material("Steel")
    skin_m = material("SkinTone")
    trousers = material("CoatNight") if key not in ("Night", "Count", "Plague") else material("Leather")
    M = {
        "fur": material("Fur"),
        "leather": material("Leather"),
        "pumpkin": material("Pumpkin"),
        "bark": material("Bark"),
        "bone": material("Bone"),
        "glass": material("PlasticWhite", tint=(0.6, 0.8, 0.95), alpha=0.4),
        "orangeglow": material("PlasticWhite", emission=(1.0, 0.55, 0.1), emission_strength=5.0),
        "cyanglow": material("PlasticWhite", emission=(0.4, 0.9, 1.0), emission_strength=6.0),
        "voidblack": material("PlasticDark", tint=(0.05, 0.05, 0.08)),
        "ice": material("PlasticWhite", tint=(0.7, 0.9, 1.0), alpha=0.6),
    }
    kind = SKINS[key]
    covers_face = kind in ("PlagueMask", "Pumpkin", "Hood")
    human_body(o, skin_m, coat_m, trousers, dark_m, face=not covers_face)
    if covers_face:  # the mask replaces the head
        o.pieces = [(p, ob) for (p, ob) in o.pieces if not (p == "Head" and ob.name.startswith(("head", "ear", "nose")))]
        for p, ob in list(o.pieces):
            pass
    # Uniform details on the rounded body
    for i in range(4):
        o.add("UpperTorso", cyl("button", 0.06, 0.05, B("UpperTorso", 0.0, 0.38 - i * 0.3, 0.52 - abs(0.0)), metal_m, axis="Y", verts=12))
    badge = lathe("badge", [(0, 0), (0.15, 0), (0.17, 0.03), (0.11, 0.05), (0, 0.05)], B("UpperTorso", -0.38, 0.3, 0.49), metal_m, 16)
    badge.rotation_euler = (-math.pi / 2, 0, 0)
    o.add("UpperTorso", badge)
    for side in (-1, 1):
        lapel = box("lapel", (0.26, 0.06, 0.62), B("UpperTorso", side * 0.18, 0.45, 0.47), coat_m, 0.03)
        lapel.rotation_euler = (0.25, side * -0.35, 0)
        o.add("UpperTorso", lapel)
        o.add("UpperTorso", box("epaulette", (0.5, 0.42, 0.07), B("UpperTorso", side * 0.72, 0.84, 0), trim_m, 0.03))
        o.add(("Left" if side < 0 else "Right") + "LowerArm", torus("cuff", 0.25, 0.05, B(("Left" if side < 0 else "Right") + "LowerArm", -side * 0.32, -0.38, 0), trim_m))
    o.add("LowerTorso", torus("belt", 0.62, 0.07, B("LowerTorso", 0, 0.2, 0), dark_m))
    o.pieces[-1][1].scale = (1.05, 0.72, 1.0)
    o.add("LowerTorso", box("buckle", (0.28, 0.06, 0.2), B("LowerTorso", 0, 0.2, 0.46), metal_m, 0.03))
    if key in ("Plague", "Witch", "Count", "Wraith", "Crimson", "Gold"):
        coat_tail = lathe("coattail", [(0.62, 0.0), (0.7, -0.6), (0.78, -1.3), (0.0, -1.3)], B("LowerTorso", 0, 0.1, 0), coat_m, 32)
        coat_tail.scale = (1.0, 0.7, 1.0)
        o.add("LowerTorso", coat_tail)
    before = len(o.pieces)
    hat(o, kind, coat_m, trim_m, dark_m, metal_m, M)
    grow_head_pieces(o, before)
    return o


def grow_head_pieces(o, start, factor=1.38, lift=0.3):
    """Scale hat/mask pieces about the head centre so they fit the big cartoon head."""
    from mathutils import Vector

    centre = Vector(B("Head"))
    for part, ob in o.pieces[start:]:
        if part != "Head":
            continue
        ob.location = centre + (ob.location - centre) * factor + Vector((0, 0, lift))
        ob.scale = (ob.scale[0] * factor, ob.scale[1] * factor, ob.scale[2] * factor)


def build_civilian():
    """Passenger body: untextured pieces whose suffix names the colour role the game tints."""
    o = Owner("Civilian")
    white = plain("TintMe", (0.85, 0.85, 0.85), 0.6)
    human_body(o, white, white, white, plain("Shoe", (0.12, 0.11, 0.1), 0.5), roles=True)
    hair = plain("Hair", (0.25, 0.17, 0.1), 0.7)
    H = "Head"
    def spikes(n, r):
        out = []
        for i in range(n):
            a = -1.2 + 2.4 * i / (n - 1)
            sp = cyl("spike", 0.22, 0.75, B(H, math.sin(a) * r * 1.15, 0.92 + 0.1 * math.cos(a * 2), -0.1 + math.cos(a) * 0.1), hair, verts=8, radius2=0.0)
            sp.rotation_euler = (-0.35, a * 0.5, 0)
            out.append(sp)
        for i in range(4):
            sp = cyl("spikeb", 0.22, 0.7, B(H, -0.45 + i * 0.3, 0.76, -0.5), hair, verts=8, radius2=0.0)
            sp.rotation_euler = (-1.0, 0, 0)
            out.append(sp)
        return out

    styles = {
        "HairShort": [ellipsoid("hs", 0.88, (0.99, 0.97, 0.62), B(H, 0, 0.52, -0.05), hair)],
        "HairLong": [ellipsoid("hl", 0.9, (1.0, 0.98, 0.66), B(H, 0, 0.5, -0.05), hair), ellipsoid("hl2", 0.78, (1.0, 0.45, 1.3), B(H, 0, -0.25, -0.42), hair)],
        "HairBun": [ellipsoid("hb", 0.88, (0.99, 0.97, 0.6), B(H, 0, 0.4, -0.05), hair), sphere("bun", 0.34, B(H, 0, 0.92, -0.58), hair)],
        "HairSpiky": [ellipsoid("hk", 0.87, (0.99, 0.97, 0.56), B(H, 0, 0.54, -0.06), hair)] + spikes(6, 0.5),
        "HairCap": [lathe("cap", [(0, 0), (0.92, 0), (0.9, 0.38), (0, 0.55)], B(H, 0, 0.5, 0), hair, 24), box("brim", (1.25, 0.8, 0.07), B(H, 0, 0.52, 0.85), hair, 0.03)],
    }
    for role, objs in styles.items():
        for ob in objs:
            o.add(H, ob, role)
    return o
