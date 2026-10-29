"""Original 3D props for Frostline Checkpoint. Every function builds one model in studs, front facing -Y."""
import math
import random

from lib import box, cut, cyl, lathe, material, sphere, torus

M = {}


def mats():
    M.update(
        white=material("MetalWhite"),
        navy=material("MetalNavy"),
        red=material("MetalRed"),
        grey=material("MetalGrey"),
        yellow=material("MetalYellow"),
        train=material("TrainBlue"),
        steel=material("Steel"),
        dark=material("PlasticDark"),
        blueplastic=material("PlasticBlue"),
        whiteplastic=material("PlasticWhite"),
        belt=material("Belt"),
        fabric=material("FabricBlue"),
        blackfabric=material("FabricBlack"),
        wood=material("Wood"),
        bark=material("Bark"),
        leaves=material("Leaves"),
        snow=material("Snow"),
        pumpkin=material("Pumpkin"),
        glass=material("PlasticWhite", tint=(0.6, 0.8, 0.95), alpha=0.35),
        screen=material("PlasticDark", emission=(0.25, 1.0, 0.6), emission_strength=1.2),
        lamp=material("PlasticWhite", emission=(1.0, 0.85, 0.6), emission_strength=4.0),
        cyan=material("PlasticWhite", emission=(0.35, 0.8, 1.0), emission_strength=3.0),
        redlight=material("PlasticWhite", emission=(1.0, 0.1, 0.05), emission_strength=3.0),
        greenlight=material("PlasticWhite", emission=(0.1, 1.0, 0.2), emission_strength=3.0),
        orangeglow=material("PlasticWhite", emission=(1.0, 0.55, 0.1), emission_strength=5.0),
        lead=material("PlasticDark", tint=(0.6, 0.6, 0.65)),
        window=material("PlasticWhite", emission=(1.0, 0.8, 0.5), emission_strength=2.5),
    )


def xray_machine():
    """Baggage X-ray: 3.8 wide, 6.5 tall, 19 long (along Y). Bags enter at -Y."""
    o = []
    L = 19.0
    # Conveyor bed with side rails and rollers
    o.append(box("bed", (3.2, L, 1.2), (0, 0, 2.0), M["grey"], 0.08))
    for x in (-1.55, 1.55):
        o.append(box("rail", (0.18, L, 0.35), (x, 0, 2.75), M["steel"], 0.05))
    o.append(box("belt", (2.8, L - 0.4, 0.12), (0, 0, 2.62), M["belt"], 0.03))
    for i in range(11):
        y = -L / 2 + 0.8 + i * (L - 1.6) / 10
        for x in (-1.3, 1.3):
            o.append(box("leg", (0.25, 0.25, 1.5), (x, y if i % 5 == 0 else -100, 0.75), M["steel"], 0.04))
    o = [ob for ob in o if ob.location.y > -50]
    for y in (-L / 2 + 0.6, L / 2 - 0.6):
        o.append(box("foot", (3.0, 0.5, 1.4), (0, y, 0.7), M["dark"], 0.08))
    # Scanner tunnel housing (hollow), rounded edges
    housing = box("housing", (3.8, 6.2, 4.3), (0, 0.8, 4.0), M["white"], 0.25, 3)
    hole = box("hole", (3.0, 7.0, 2.2), (0, 0.8, 3.65), M["white"], 0)
    cut(housing, hole)
    o.append(housing)
    # Lead curtains at both openings
    for y in (0.8 - 3.05, 0.8 + 3.05):
        for i in range(6):
            o.append(box("curtain", (0.46, 0.05, 2.1), (-1.25 + i * 0.5, y, 3.6), M["lead"], 0.01))
    # Yellow warning band, radiation logo panel, status lights
    o.append(box("band", (3.85, 6.25, 0.35), (0, 0.8, 5.6), M["yellow"], 0.05))
    o.append(box("sticker", (0.05, 1.2, 1.2), (-1.93, 0.8, 4.4), M["yellow"], 0.02))
    for i, m in enumerate((M["greenlight"], M["redlight"])):
        o.append(cyl("status", 0.16, 0.12, (-0.8 + i * 0.4, 0.8 - 3.12, 5.8), m, axis="Y", verts=16))
    # Exit roller table at +Y end (slanted)
    o.append(box("ramp", (3.2, 2.0, 0.3), (0, L / 2 + 0.8, 2.45), M["steel"], 0.05, rot=(-0.12, 0, 0)))
    # Operator monitor on an arm at the exit end
    o.append(box("arm", (0.2, 0.2, 2.6), (1.7, 6.5, 4.1), M["steel"], 0.04))
    o.append(box("monitor", (0.25, 1.9, 1.3), (1.8, 6.5, 5.6), M["dark"], 0.08))
    o.append(box("monitorscreen", (0.05, 1.7, 1.1), (1.68, 6.5, 5.6), M["screen"], 0.01))
    return o


def body_scanner():
    """Walk-through body scanner arch: 5.4 wide (X), 9.4 tall, 3 deep (Y). Walk along Y."""
    o = []
    for x in (-2.25, 2.25):
        pillar = box("pillar", (0.9, 2.8, 8.4), (x, 0, 4.2), M["white"], 0.3, 3)
        o.append(pillar)
        o.append(box("strip", (0.06, 0.3, 7.2), (x * 0.78, -0.2, 4.5), M["cyan"], 0.02))
        o.append(box("strip", (0.06, 0.3, 7.2), (x * 0.78, 0.2, 4.5), M["cyan"], 0.02))
        o.append(box("base", (1.3, 3.0, 0.3), (x, 0, 0.15), M["grey"], 0.08))
    top = box("top", (5.4, 2.8, 1.1), (0, 0, 8.9), M["white"], 0.35, 3)
    o.append(top)
    o.append(box("toplight", (3.6, 0.5, 0.06), (0, 0, 8.32), M["cyan"], 0.02))
    o.append(box("panel", (1.6, 0.06, 0.7), (0, -1.42, 9.0), M["dark"], 0.03))
    o.append(box("panelglow", (1.3, 0.03, 0.4), (0, -1.46, 9.0), M["greenlight"], 0.01))
    # floor pad with footprints
    o.append(box("pad", (3.4, 2.2, 0.06), (0, 0, 0.03), M["yellow"], 0.02))
    for x in (-0.45, 0.45):
        o.append(box("foot", (0.45, 0.95, 0.03), (x, 0, 0.07), M["dark"], 0.02))
    # Side control console
    o.append(box("console", (0.9, 1.2, 3.4), (3.4, -0.6, 1.7), M["grey"], 0.12))
    o.append(box("consoletop", (0.95, 1.25, 0.12), (3.4, -0.6, 3.45), M["dark"], 0.04, rot=(0.25, 0, 0)))
    return o


def locker():
    """Single tall locker 3 wide, 7.4 tall, 2.6 deep, door on -Y."""
    o = []
    body = box("body", (3.0, 2.6, 7.4), (0, 0, 3.7), M["red"], 0.06)
    o.append(body)
    o.append(box("door", (2.7, 0.08, 7.0), (0, -1.33, 3.7), M["red"], 0.04))
    for i in range(6):
        vent = box("vent", (1.6, 0.06, 0.08), (0, -1.39, 6.5 - i * 0.22), M["dark"], 0.01)
        o.append(vent)
    for i in range(4):
        o.append(box("lowvent", (1.6, 0.06, 0.08), (0, -1.39, 1.2 - i * 0.2 + 0.6), M["dark"], 0.01))
    o.append(box("handle", (0.12, 0.14, 0.9), (1.05, -1.45, 3.8), M["steel"], 0.04))
    o.append(box("nameplate", (0.8, 0.04, 0.3), (0, -1.39, 5.0), M["steel"], 0.01))
    for z in (1.2, 6.2):
        o.append(cyl("hinge", 0.07, 0.4, (-1.38, -1.38, z), M["steel"], verts=12))
    o.append(box("plinth", (3.0, 2.4, 0.25), (0, 0.05, 0.12), M["dark"], 0.03))
    return o


def waiting_chairs(seats=4):
    """Row of airport-style seats on a beam: seats*2.4 wide, 4.2 tall, 2.4 deep. People face -Y."""
    o = []
    W = seats * 2.4
    o.append(box("beam", (W - 0.4, 0.5, 0.35), (0, 0.1, 1.3), M["steel"], 0.08))
    for x in (-W / 2 + 0.7, W / 2 - 0.7):
        o.append(box("leg", (0.3, 2.0, 1.25), (x, 0.1, 0.62), M["steel"], 0.1))
        o.append(box("legfoot", (0.5, 2.2, 0.12), (x, 0.1, 0.06), M["dark"], 0.04))
    for i in range(seats):
        x = (i - (seats - 1) / 2) * 2.4
        o.append(box("seat", (2.1, 2.0, 0.35), (x, -0.1, 1.95), M["blueplastic"], 0.15, 3))
        o.append(box("back", (2.1, 0.32, 2.0), (x, 1.0, 3.05), M["blueplastic"], 0.15, 3, rot=(0.14, 0, 0)))
        o.append(box("cushion", (1.8, 1.7, 0.18), (x, -0.15, 2.18), M["fabric"], 0.08, 2))
        if i < seats - 1:
            o.append(box("arm", (0.18, 1.6, 0.12), (x + 1.2, -0.1, 2.75), M["steel"], 0.05))
            o.append(box("armpost", (0.14, 0.14, 0.7), (x + 1.2, 0.5, 2.35), M["steel"], 0.04))
    return o


def office_chair():
    """Swivel chair 2.2 x 2.2, 4.4 tall, faces -Y."""
    o = []
    for i in range(5):
        a = i * 2 * math.pi / 5
        o.append(box("spoke", (0.2, 1.1, 0.15), (math.sin(a) * 0.55, math.cos(a) * 0.55, 0.32), M["dark"], 0.05, rot=(0, 0, -a)))
        o.append(sphere("wheel", 0.15, (math.sin(a) * 1.05, math.cos(a) * 1.05, 0.15), M["dark"], segments=12, rings=8))
    o.append(cyl("post", 0.13, 1.4, (0, 0, 1.0), M["steel"], verts=16))
    o.append(box("seat", (1.9, 1.8, 0.35), (0, 0, 1.85), M["blackfabric"], 0.15, 3))
    o.append(box("back", (1.8, 0.3, 2.0), (0, 0.85, 3.1), M["blackfabric"], 0.15, 3, rot=(0.12, 0, 0)))
    o.append(box("spine", (0.25, 0.15, 1.0), (0, 0.85, 2.2), M["dark"], 0.05))
    for x in (-1.0, 1.0):
        o.append(box("armpost", (0.12, 0.12, 0.6), (x, 0.1, 2.25), M["dark"], 0.04))
        o.append(box("armpad", (0.25, 1.0, 0.12), (x, 0.1, 2.6), M["dark"], 0.05))
    return o


def office_desk():
    """Officer desk 8 wide, 3.25 tall, 2.6 deep, with PC, keyboard, phone, mug. User sits on the -Y side."""
    o = []
    o.append(box("top", (8, 2.6, 0.18), (0, 0, 3.15), M["wood"], 0.05))
    o.append(box("drawers", (2.2, 2.4, 2.9), (2.8, 0.05, 1.5), M["grey"], 0.06))
    for i in range(3):
        o.append(box("drawer", (2.0, 0.06, 0.8), (2.8, -1.17, 2.5 - i * 0.92), M["grey"], 0.03))
        o.append(box("pull", (0.6, 0.08, 0.08), (2.8, -1.22, 2.6 - i * 0.92), M["steel"], 0.02))
    o.append(box("legL", (0.15, 2.3, 3.0), (-3.85, 0, 1.5), M["steel"], 0.04))
    o.append(box("modesty", (5.6, 0.1, 1.6), (-1, 1.15, 2.2), M["grey"], 0.03))
    # computer
    o.append(box("monbase", (0.8, 0.6, 0.06), (-0.6, 0.6, 3.27), M["dark"], 0.03))
    o.append(box("monneck", (0.15, 0.1, 0.6), (-0.6, 0.7, 3.55), M["dark"], 0.02))
    o.append(box("monitor", (2.2, 0.15, 1.35), (-0.6, 0.62, 4.4), M["dark"], 0.05))
    o.append(box("monscreen", (2.05, 0.03, 1.2), (-0.6, 0.53, 4.4), M["screen"], 0.01))
    o.append(box("keyboard", (1.7, 0.6, 0.07), (-0.6, -0.5, 3.28), M["dark"], 0.03))
    o.append(box("mouse", (0.18, 0.28, 0.07), (0.5, -0.5, 3.28), M["dark"], 0.03))
    o.append(box("phone", (0.6, 0.5, 0.2), (2.6, 0.4, 3.35), M["dark"], 0.05))
    o.append(box("handset", (0.15, 0.6, 0.12), (2.85, 0.4, 3.5), M["dark"], 0.05))
    o.append(cyl("mug", 0.2, 0.45, (-3.2, -0.3, 3.47), M["whiteplastic"], verts=20))
    o.append(box("papers", (0.9, 1.2, 0.08), (1.5, -0.3, 3.28), M["whiteplastic"], 0.01, rot=(0, 0, 0.2)))
    return o


def stanchion():
    """Queue post: 1 x 1 base, 3.2 tall, belt cassette on top."""
    return [
        lathe("base", [(0, 0), (0.5, 0), (0.5, 0.06), (0.35, 0.18), (0.08, 0.22), (0, 0.22)], (0, 0, 0), M["steel"], 32),
        cyl("post", 0.09, 2.8, (0, 0, 1.6), M["steel"], verts=20),
        cyl("head", 0.17, 0.35, (0, 0, 3.0), M["navy"], verts=20),
        cyl("cap", 0.18, 0.05, (0, 0, 3.2), M["steel"], verts=20),
    ]


def coffee_machine():
    """Coffee machine 3.4 wide, 6 tall, 2.6 deep, front -Y."""
    o = []
    o.append(box("body", (3.2, 2.4, 6.0), (0, 0, 3.0), M["grey"], 0.15, 3))
    o.append(box("front", (2.8, 0.1, 2.0), (0, -1.22, 4.6), M["navy"], 0.05))
    o.append(box("display", (1.6, 0.05, 0.7), (0, -1.28, 5.0), M["orangeglow"], 0.02))
    for i in range(6):
        o.append(cyl("button", 0.13, 0.08, (-1.0 + i * 0.4, -1.3, 4.1), M["steel"], axis="Y", verts=16))
    nook = box("nook", (1.6, 1.4, 1.6), (0, -0.6, 2.4), M["grey"], 0)
    cut(o[0], nook)
    o.append(box("drip", (1.4, 1.0, 0.1), (0, -0.6, 1.62), M["steel"], 0.03))
    o.append(cyl("spout", 0.1, 0.4, (0, -0.6, 3.0), M["steel"], verts=12))
    o.append(cyl("cup", 0.25, 0.55, (0, -0.65, 1.95), M["whiteplastic"], verts=20, radius2=0.2))
    o.append(box("sign", (2.6, 0.04, 0.5), (0, -1.24, 5.7), M["orangeglow"], 0.01))
    return o


def vending_machine():
    """Drinks vending machine 4 wide, 7.5 tall, 3 deep, front -Y."""
    o = []
    body = box("body", (4.0, 3.0, 7.5), (0, 0, 3.75), M["red"], 0.15, 3)
    o.append(body)
    o.append(box("glass", (2.6, 0.08, 5.0), (-0.45, -1.48, 4.4), M["glass"], 0.03))
    o.append(box("interior", (2.6, 0.1, 5.0), (-0.45, -1.2, 4.4), M["whiteplastic"], 0.01))
    colors = [M["blueplastic"], M["red"], M["yellow"], M["navy"]]
    for row in range(5):
        for col in range(5):
            o.append(cyl("can", 0.17, 0.6, (-1.45 + col * 0.5, -1.35, 2.45 + row * 0.95), colors[(row + col) % 4], verts=12))
        o.append(box("shelf", (2.6, 0.5, 0.05), (-0.45, -1.3, 2.1 + row * 0.95), M["steel"], 0.01))
    o.append(box("panel", (0.9, 0.06, 5.0), (1.45, -1.5, 4.4), M["dark"], 0.03))
    o.append(box("paneldisplay", (0.6, 0.04, 0.4), (1.45, -1.54, 6.3), M["greenlight"], 0.01))
    for i in range(4):
        for j in range(3):
            o.append(box("key", (0.16, 0.05, 0.16), (1.25 + j * 0.2, -1.55, 5.5 - i * 0.22), M["steel"], 0.02))
    o.append(box("tray", (2.4, 0.2, 0.7), (-0.45, -1.45, 1.0), M["dark"], 0.05))
    o.append(box("topsign", (3.8, 0.1, 0.8), (0, -1.5, 7.2), M["orangeglow"], 0.03))
    return o


def plant():
    """Potted plant 3.4 wide, 6 tall."""
    o = [lathe("pot", [(0, 0.05), (1.0, 0.05), (1.3, 1.9), (1.35, 2.0), (1.1, 2.0), (0, 2.0)], (0, 0, 0), M["grey"], 32)]
    o.append(cyl("soil", 1.15, 0.05, (0, 0, 1.9), M["bark"], verts=24))
    rnd = random.Random(5)
    for i in range(22):
        a = i * 2.39996
        h = rnd.uniform(1.4, 2.8)
        tilt = rnd.uniform(0.25, 0.85)
        leaf = sphere("leaf", 0.5, (0, 0, 0), M["leaves"], scale=(0.42, 0.05, h), segments=14, rings=10)
        # lean outwards from the pot centre
        lx, ly = math.cos(a), math.sin(a)
        leaf.location = (lx * (0.25 + math.sin(tilt) * h * 0.45), ly * (0.25 + math.sin(tilt) * h * 0.45), 1.95 + math.cos(tilt) * h * 0.45)
        leaf.rotation_euler = (0, tilt, a)
        o.append(leaf)
    return o


def train_car():
    """Night-train sleeper carriage: 9.6 wide (X), 12 tall, 43 long (Y). Doors on the -X (platform) side."""
    o = []
    L = 42.0
    body = box("body", (9.2, L, 8.4), (0, 0, 6.6), M["train"], 0.6, 4)
    o.append(body)
    roof = cyl("roof", 4.6, L - 0.4, (0, 0, 10.8), M["grey"], axis="Y", verts=40)
    roof.scale = (1, 0.32, 1)
    o.append(roof)
    o.append(box("stripe", (9.3, L - 0.6, 0.5), (0, 0, 4.0), M["red"], 0.1))
    o.append(box("stripe2", (9.3, L - 0.6, 0.15), (0, 0, 9.4), M["yellow"], 0.05))
    # windows on both sides (lit)
    for side in (-1, 1):
        for i in range(7):
            y = -L / 2 + 5 + i * 5.3
            o.append(box("window", (0.1, 3.4, 2.3), (side * 4.62, y, 7.4), M["window"], 0.3, 3))
            o.append(box("frame", (0.12, 3.7, 0.15), (side * 4.65, y, 6.15), M["steel"], 0.04))
    # doors (platform side and other)
    for side in (-1, 1):
        for y in (-L / 2 + 1.8, L / 2 - 1.8):
            o.append(box("door", (0.12, 3.0, 6.6), (side * 4.62, y, 5.7), M["grey"], 0.1))
            o.append(box("doorwin", (0.14, 1.6, 1.8), (side * 4.65, y, 7.6), M["window"], 0.15))
            o.append(box("step", (0.8, 3.0, 0.2), (side * 4.9, y, 2.3), M["steel"], 0.05))
    # underframe and bogies
    o.append(box("underframe", (7.6, L - 3, 1.3), (0, 0, 1.9), M["dark"], 0.1))
    for y in (-L / 2 + 6, L / 2 - 6):
        o.append(box("bogie", (6.4, 6.0, 1.0), (0, y, 1.4), M["dark"], 0.15))
        for dy in (-1.8, 1.8):
            for x in (-3.0, 3.0):
                o.append(cyl("wheel", 1.05, 0.5, (x, y + dy, 1.05), M["steel"], axis="X", verts=24))
    # gangway bellows at the ends
    for y in (-L / 2 - 0.3, L / 2 + 0.3):
        o.append(box("bellows", (3.4, 0.8, 7.2), (0, y, 6.4), M["dark"], 0.2))
    # roof vents
    for i in range(5):
        o.append(box("vent", (1.6, 1.6, 0.5), (0, -L / 2 + 6 + i * 7.5, 12.3), M["grey"], 0.2))
    return o


def pine_tree():
    """Snowy pine ~30 tall."""
    o = [cyl("trunk", 0.9, 9, (0, 0, 4.5), M["bark"], verts=12, radius2=0.6)]
    rnd = random.Random(9)
    tiers = 6
    for t in range(tiers):
        z = 4 + t * 4.0
        r = 8.0 - t * 1.15
        cone = cyl("tier", r, 6.0, (0, 0, z + 2.5), M["leaves"], verts=14, radius2=0.3)
        cone.rotation_euler = (0, 0, rnd.uniform(0, 1))
        o.append(cone)
        cap = cyl("snowcap", r * 0.82, 1.6, (0, 0, z + 3.0), M["snow"], verts=14, radius2=r * 0.2)
        cap.rotation_euler = (0, 0, rnd.uniform(0, 1))
        o.append(cap)
    o.append(sphere("tip", 0.6, (0, 0, 4 + tiers * 4.0 + 1.0), M["snow"], scale=(1, 1, 1.6), segments=12, rings=8))
    return o


def street_lamp():
    """Victorian-style street lamp ~17 tall, the head hangs toward -Y."""
    o = [lathe("base", [(0, 0), (0.9, 0), (0.9, 0.4), (0.55, 0.9), (0.35, 1.8), (0.3, 2.2), (0, 2.2)], (0, 0, 0), M["dark"], 24)]
    o.append(cyl("pole", 0.22, 13, (0, 0, 8.6), M["dark"], verts=16))
    o.append(torus("ring", 0.35, 0.08, (0, 0, 3.0), M["dark"]))
    o.append(torus("ring", 0.3, 0.07, (0, 0, 14.6), M["dark"]))
    arm = cyl("arm", 0.12, 4.2, (0, -2.0, 15.4), M["dark"], axis="Y", verts=12)
    o.append(arm)
    o.append(torus("curl", 0.6, 0.08, (0, -1.0, 14.7), M["dark"], rot=(0, math.pi / 2, 0)))
    o.append(cyl("hanger", 0.06, 0.8, (0, -4.0, 15.0), M["dark"], verts=8))
    o.append(lathe("hood", [(0, 0.9), (0.15, 0.9), (1.0, 0.25), (1.05, 0.0), (0, 0.0)], (0, -4.0, 13.8), M["dark"], 24))
    o.append(cyl("bulb", 0.7, 1.2, (0, -4.0, 13.3), M["lamp"], verts=20, radius2=0.85))
    return o


def pumpkin():
    """Carved jack-o'-lantern ~2.6 wide: ribbed hollow shell, carved face, candle glow inside."""
    import bmesh
    import bpy

    mesh = bpy.data.meshes.new("shell")
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=60, v_segments=28, radius=1.0)
    for v in bm.verts:
        x, y, z = v.co
        ang = math.atan2(y, x)
        rib = 1 + 0.07 * math.cos(ang * 10)
        flat = 0.8 if z > 0 else 0.86
        squash = 1 - 0.18 * (abs(z) ** 6)
        v.co = (x * 1.3 * rib * squash, y * 1.3 * rib * squash, z * 1.3 * flat)
    bm.to_mesh(mesh)
    bm.free()
    shell = bpy.data.objects.new("shell", mesh)
    bpy.context.scene.collection.objects.link(shell)
    shell.location = (0, 0, 1.1)
    shell.data.materials.append(M["pumpkin"])
    for poly in mesh.polygons:
        poly.use_smooth = True
    solid = shell.modifiers.new("Solid", "SOLIDIFY")
    solid.thickness = 0.12
    from lib import apply_modifiers

    apply_modifiers(shell)
    # Carve the face through the front (-Y)
    for x in (-0.45, 0.45):
        cut(shell, cyl("eye", 0.3, 1.2, (x, -1.1, 1.35), M["pumpkin"], verts=3, rot=(math.pi / 2, 0, math.pi)))
    cut(shell, cyl("nose", 0.15, 1.2, (0, -1.1, 1.05), M["pumpkin"], verts=3, rot=(math.pi / 2, 0, math.pi)))
    mouth = box("mouth", (1.4, 1.2, 0.32), (0, -1.1, 0.7), M["pumpkin"], 0)
    cut(shell, mouth)
    o = [shell]
    for x in (-0.32, 0.32):
        o.append(box("tooth", (0.2, 0.3, 0.2), (x, -1.12, 0.8), M["pumpkin"], 0.03))
    o.append(sphere("glow", 0.95, (0, 0, 1.1), M["orangeglow"], scale=(1, 1, 0.8), segments=20, rings=12))
    o.append(cyl("stem", 0.16, 0.6, (0.05, 0.0, 2.25), M["bark"], verts=10, radius2=0.1, rot=(0.25, 0.1, 0)))
    return o


MODELS = {
    "XRayMachine": (xray_machine, 4.0),
    "BodyScanner": (body_scanner, 4.0),
    "Locker": (locker, 4.0),
    "WaitingChairs": (waiting_chairs, 3.0),
    "OfficeChair": (office_chair, 3.0),
    "OfficeDesk": (office_desk, 4.0),
    "Stanchion": (stanchion, 2.0),
    "CoffeeMachine": (coffee_machine, 4.0),
    "VendingMachine": (vending_machine, 4.0),
    "Plant": (plant, 3.0),
    "TrainCar": (train_car, 8.0),
    "PineTree": (pine_tree, 8.0),
    "StreetLamp": (street_lamp, 4.0),
    "Pumpkin": (pumpkin, 3.0),
}
