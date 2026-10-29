"""Original seamless PBR texture sets (albedo, normal, roughness, metalness) generated procedurally."""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

N = 1024
rng = np.random.default_rng(77)


def tile_noise(cells, octaves=5, persistence=0.5, seed=0):
    """Seamless fractal value noise in [0,1]."""
    r = np.random.default_rng(seed)
    out = np.zeros((N, N))
    amp, total = 1.0, 0.0
    for o in range(octaves):
        c = cells * 2**o
        if c > N:
            break
        grid = r.random((c, c))
        img = Image.fromarray((grid * 255).astype(np.uint8))
        # wrap-pad so bicubic resize stays seamless
        big = np.tile(grid, (3, 3))
        im = Image.fromarray((big * 65535).astype(np.uint16).astype(np.int32), mode="I").resize((N * 3, N * 3), Image.BICUBIC)
        layer = np.array(im, dtype=np.float64)[N : 2 * N, N : 2 * N] / 65535
        out += layer * amp
        total += amp
        amp *= persistence
        del img
    out /= total
    return (out - out.min()) / (out.max() - out.min() + 1e-9)


def normal_from_height(h, strength=4.0):
    dx = (np.roll(h, -1, 1) - np.roll(h, 1, 1)) * strength
    dy = (np.roll(h, -1, 0) - np.roll(h, 1, 0)) * strength
    nz = np.ones_like(h)
    n = np.stack([-dx, dy, nz], -1)
    n /= np.linalg.norm(n, axis=-1, keepdims=True)
    return ((n * 0.5 + 0.5) * 255).astype(np.uint8)


def scratches(count, length, seed):
    r = np.random.default_rng(seed)
    m = np.zeros((N, N))
    for _ in range(count):
        x, y = r.integers(0, N, 2)
        ang = r.uniform(0, np.pi)
        L = r.integers(length // 3, length)
        t = np.arange(L)
        xs = (x + np.cos(ang) * t).astype(int) % N
        ys = (y + np.sin(ang) * t).astype(int) % N
        m[ys, xs] = np.maximum(m[ys, xs], r.uniform(0.4, 1))
    return m


def save(out, name, albedo, height, rough, metal, nstrength=4.0):
    out.mkdir(parents=True, exist_ok=True)
    Image.fromarray(np.clip(albedo * 255, 0, 255).astype(np.uint8)).save(out / f"{name}_color.png")
    Image.fromarray(normal_from_height(height, nstrength)).save(out / f"{name}_normal.png")
    Image.fromarray(np.clip(rough * 255, 0, 255).astype(np.uint8)).save(out / f"{name}_roughness.png")
    Image.fromarray(np.clip(metal * 255, 0, 255).astype(np.uint8)).save(out / f"{name}_metalness.png")
    print("texture", name)


def rgb(c):
    return np.array(c, dtype=np.float64) / 255


def painted_metal(out, name, color, seed):
    base = rgb(color)
    n1 = tile_noise(4, 6, 0.55, seed)
    n2 = tile_noise(32, 3, 0.5, seed + 1)
    sc = scratches(70, 90, seed + 2) * 0.7
    grime = np.clip((tile_noise(3, 5, 0.6, seed + 3) - 0.68) * 1.6, 0, 1)
    alb = base[None, None, :] * (0.9 + 0.12 * n1[..., None] + 0.04 * n2[..., None])
    alb = alb * (1 - 0.35 * grime[..., None]) + grime[..., None] * rgb((40, 36, 32)) * 0.35
    bare = rgb((165, 168, 172))
    alb = alb * (1 - sc[..., None]) + bare * sc[..., None]
    rough = 0.42 + 0.15 * n2 + 0.25 * grime - 0.2 * sc
    metal = 0.15 + 0.85 * sc
    height = 0.6 * n2 * 0.1 - sc * 0.4 + n1 * 0.05
    save(out, name, alb, height, rough, metal, 3.0)


def brushed_steel(out, name):
    streak = tile_noise(64, 3, 0.5, 11)
    streak = np.repeat(streak.mean(axis=1, keepdims=True), N, axis=1) * 0.6 + tile_noise(256, 2, 0.5, 12) * 0.4
    sc = scratches(120, 80, 13)
    alb = rgb((178, 182, 188))[None, None, :] * (0.85 + 0.2 * streak[..., None])
    rough = 0.28 + 0.18 * streak + 0.1 * sc
    save(out, name, alb, streak * 0.2 - sc * 0.3, rough, np.full((N, N), 0.95), 2.0)


def plastic(out, name, color, seed):
    n = tile_noise(48, 3, 0.5, seed)
    big = tile_noise(4, 4, 0.5, seed + 1)
    grime = np.clip((big - 0.6) * 2.5, 0, 1)
    alb = rgb(color)[None, None, :] * (0.95 + 0.05 * n[..., None]) * (1 - 0.18 * grime[..., None])
    save(out, name, alb, n * 0.08, 0.5 + 0.1 * n + 0.15 * grime, np.zeros((N, N)), 1.5)


def rubber_belt(out, name):
    y = np.arange(N)[:, None] * np.ones((1, N))
    ridges = (np.sin(y / N * 2 * np.pi * 48) > 0.6).astype(float)
    n = tile_noise(64, 3, 0.5, 21)
    alb = rgb((26, 26, 28))[None, None, :] * (0.9 + 0.2 * n[..., None]) + ridges[..., None] * 0.02
    save(out, name, alb, ridges * 0.6 + n * 0.1, 0.85 - ridges * 0.1, np.zeros((N, N)), 4.0)


def fabric(out, name, color, seed):
    x = np.arange(N)[None, :] * np.ones((N, 1))
    y = x.T
    weave = (np.sin(x / N * 2 * np.pi * 160) * np.sin(y / N * 2 * np.pi * 160)) * 0.5 + 0.5
    n = tile_noise(8, 5, 0.5, seed)
    alb = rgb(color)[None, None, :] * (0.8 + 0.15 * weave[..., None] + 0.12 * n[..., None])
    save(out, name, alb, weave * 0.4, 0.9 + 0.05 * n, np.zeros((N, N)), 3.0)


def wood(out, name, color, seed):
    x = np.arange(N)[None, :] * np.ones((N, 1))
    warp = tile_noise(6, 5, 0.55, seed)
    rings = np.sin((x / N * 2 * np.pi * 14) + warp * 9) * 0.5 + 0.5
    grain = tile_noise(128, 2, 0.5, seed + 1)
    alb = rgb(color)[None, None, :] * (0.72 + 0.28 * rings[..., None] + 0.08 * grain[..., None])
    save(out, name, alb, rings * 0.15 + grain * 0.05, 0.55 + 0.15 * grain, np.zeros((N, N)), 2.0)


def leaves(out, name, seed):
    n = tile_noise(24, 5, 0.6, seed)
    m = tile_noise(6, 4, 0.5, seed + 1)
    alb = rgb((40, 82, 52))[None, None, :] * (0.6 + 0.6 * n[..., None]) + rgb((10, 20, 5)) * m[..., None]
    save(out, name, alb, n, 0.8 + 0.1 * n, np.zeros((N, N)), 5.0)


def snow(out, name):
    n = tile_noise(16, 6, 0.55, 31)
    sparkle = (rng.random((N, N)) > 0.997).astype(float)
    alb = np.ones((N, N, 3)) * (0.88 + 0.1 * n[..., None]) * rgb((236, 242, 252))[None, None, :] + sparkle[..., None] * 0.1
    save(out, name, alb, n, 0.85 - 0.4 * sparkle, np.zeros((N, N)), 3.0)


def pumpkin_skin(out, name):
    x = np.arange(N)[None, :] * np.ones((N, 1))
    ribs = np.abs(np.sin(x / N * np.pi * 10))
    n = tile_noise(16, 5, 0.5, 41)
    alb = rgb((235, 110, 20))[None, None, :] * (0.65 + 0.35 * ribs[..., None]) * (0.9 + 0.15 * n[..., None])
    save(out, name, alb, ribs * 0.5 + n * 0.1, 0.55 + 0.2 * n, np.zeros((N, N)), 3.0)


# --- Floor / wall textures for the station (Roblox MaterialVariants) ---
def terrazzo(out, name):
    base = tile_noise(8, 4, 0.5, 51)
    chips = np.zeros((N, N, 3))
    r = np.random.default_rng(52)
    alb = np.ones((N, N, 3)) * rgb((196, 198, 204))[None, None, :] * (0.92 + 0.08 * base[..., None])
    for _ in range(2600):
        x, y = r.integers(0, N, 2)
        s = r.integers(2, 9)
        col = rgb(r.choice([(60, 70, 110), (230, 230, 235), (120, 120, 130), (40, 40, 48)]))
        ys, xs = np.ogrid[-s : s + 1, -s : s + 1]
        mask = xs**2 + ys**2 <= s * s
        yy, xx = (np.arange(-s, s + 1)[:, None] + y) % N, (np.arange(-s, s + 1)[None, :] + x) % N
        alb[yy, xx][mask] = col
        sub = alb[yy, xx]
        sub[mask] = col
        alb[yy, xx] = sub
    del chips
    save(out, name, alb, base * 0.05, 0.3 + 0.1 * base, np.zeros((N, N)), 1.0)


def floor_tiles(out, name, color, tiles=4):
    x = np.arange(N)[None, :] * np.ones((N, 1))
    y = x.T
    t = N // tiles
    grout = ((x % t) < 6) | ((y % t) < 6)
    n = tile_noise(16, 5, 0.5, 61)
    per_tile = tile_noise(tiles, 1, 0.5, 62)
    alb = rgb(color)[None, None, :] * (0.88 + 0.1 * n[..., None] + 0.06 * per_tile[..., None])
    alb[grout] = rgb((70, 72, 76))
    height = np.where(grout, 0.0, 1.0) + n * 0.03
    rough = np.where(grout, 0.95, 0.35 + 0.15 * n)
    save(out, name, alb, height, rough, np.zeros((N, N)), 6.0)


def painted_plaster(out, name, color):
    n = tile_noise(32, 6, 0.6, 71)
    stain = np.clip((tile_noise(2, 5, 0.6, 72) - 0.75) * 1.5, 0, 1)
    alb = rgb(color)[None, None, :] * (0.94 + 0.06 * n[..., None]) * (1 - 0.15 * stain[..., None])
    save(out, name, alb, n, 0.8 + 0.1 * n, np.zeros((N, N)), 2.5)


def carpet(out, name, color):
    n = tile_noise(128, 3, 0.6, 81)
    pattern = tile_noise(8, 3, 0.5, 82)
    alb = rgb(color)[None, None, :] * (0.75 + 0.3 * n[..., None]) * (0.9 + 0.15 * (pattern[..., None] > 0.5))
    save(out, name, alb, n, np.full((N, N), 0.97), np.zeros((N, N)), 4.0)


if __name__ == "__main__":
    out = Path(sys.argv[1])
    painted_metal(out, "MetalWhite", (214, 218, 226), 1)
    painted_metal(out, "MetalNavy", (34, 52, 104), 2)
    painted_metal(out, "MetalRed", (150, 34, 34), 3)
    painted_metal(out, "MetalGrey", (92, 96, 104), 4)
    painted_metal(out, "MetalYellow", (232, 190, 40), 5)
    painted_metal(out, "TrainBlue", (26, 44, 78), 6)
    brushed_steel(out, "Steel")
    plastic(out, "PlasticDark", (34, 35, 40), 7)
    plastic(out, "PlasticBlue", (40, 96, 196), 8)
    plastic(out, "PlasticWhite", (232, 234, 238), 9)
    rubber_belt(out, "Belt")
    fabric(out, "FabricBlue", (36, 74, 168), 10)
    fabric(out, "FabricBlack", (30, 30, 34), 11)
    wood(out, "Wood", (120, 82, 52), 12)
    wood(out, "Bark", (70, 52, 38), 13)
    leaves(out, "Leaves", 14)
    snow(out, "Snow")
    pumpkin_skin(out, "Pumpkin")
    terrazzo(out, "FloorTerrazzo")
    floor_tiles(out, "FloorTiles", (128, 136, 152))
    painted_plaster(out, "WallPlaster", (210, 204, 190))
    carpet(out, "CarpetBlue", (52, 66, 110))
