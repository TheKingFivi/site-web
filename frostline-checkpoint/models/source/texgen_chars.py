"""Extra textures for skins and the monster (512px to keep files small)."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

import texgen as T


def shrink(out, name):
    for kind in ("color", "normal", "roughness", "metalness"):
        p = out / f"{name}_{kind}.png"
        Image.open(p).resize((512, 512), Image.LANCZOS).save(p)


def monster_skin(out, name):
    n = T.tile_noise(6, 6, 0.6, 91)
    veins = np.abs(T.tile_noise(12, 4, 0.5, 92) - 0.5) < 0.025
    pores = T.tile_noise(128, 2, 0.5, 93)
    alb = T.rgb((58, 56, 62))[None, None, :] * (0.55 + 0.6 * n[..., None]) + pores[..., None] * 0.03
    alb[veins] = alb[veins] * 0.5 + T.rgb((70, 10, 20)) * 0.5
    T.save(out, name, alb, n * 0.6 + pores * 0.2 - veins * 0.4, 0.55 + 0.2 * pores, np.zeros((T.N, T.N)), 5.0)


def bone(out, name):
    n = T.tile_noise(24, 5, 0.5, 94)
    alb = T.rgb((222, 214, 190))[None, None, :] * (0.8 + 0.25 * n[..., None])
    T.save(out, name, alb, n * 0.4, 0.45 + 0.2 * n, np.zeros((T.N, T.N)), 3.0)


if __name__ == "__main__":
    out = Path(sys.argv[1])
    coats = {
        "Standard": ((40, 52, 78), (220, 180, 70)),
        "Night": ((22, 24, 30), (90, 200, 255)),
        "Arctic": ((210, 220, 230), (60, 120, 200)),
        "Crimson": ((120, 20, 26), (240, 200, 90)),
        "Gold": ((196, 158, 60), (255, 255, 255)),
        "Plague": ((30, 30, 32), (120, 100, 70)),
        "Pumpkin": ((60, 30, 70), (255, 130, 20)),
        "Witch": ((70, 20, 80), (120, 230, 90)),
        "Count": ((16, 12, 14), (170, 10, 20)),
        "Wraith": ((180, 230, 255), (40, 160, 255)),
    }
    for key, (coat, trim) in coats.items():
        T.fabric(out, f"Coat{key}", coat, hash(key) % 1000)
        shrink(out, f"Coat{key}")
        T.painted_metal(out, f"Trim{key}", trim, hash(key) % 1000 + 1)
        shrink(out, f"Trim{key}")
    T.fabric(out, "Fur", (238, 236, 230), 95)
    shrink(out, "Fur")
    T.plastic(out, "Leather", (34, 28, 24), 96)
    shrink(out, "Leather")
    monster_skin(out, "MonsterSkin")
    bone(out, "Bone")
    T.plastic(out, "SkinTone", (234, 196, 164), 97)
    shrink(out, "SkinTone")
