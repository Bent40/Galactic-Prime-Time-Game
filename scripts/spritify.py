#!/usr/bin/env python3
"""spritify — turn a generated still (GPT route) into a game-ready sprite.

The art-pipeline half the generator can't do (docs/art/generation-prompts.md verdict):
  1. background removal -> true alpha (chroma-key uniform bg OR checkerboard)
  2. palette quantization (default 32 colors — keeps the HD-pixel look coherent)
  3. nearest-neighbor resize to the target sprite height (default 96px key pose,
     48px motion frames per the hybrid 64/48 technique)
  4. tight crop to content + transparent padding to a clean power-friendly canvas

Usage:
  python3 scripts/spritify.py IN.png OUT.png [--height 96] [--colors 32]
                              [--bg auto|checker|none] [--tol 24]
  python3 scripts/spritify.py --self-test

Honesty note: this is deterministic post-processing; it will not fix a bad source.
"""
from __future__ import annotations

import argparse
import sys

from PIL import Image


def _key_color(img: Image.Image, color: tuple, tol: int) -> Image.Image:
    px = img.load()
    w, h = img.size
    for y in range(h):
        for x in range(w):
            r, g, b, a = px[x, y]
            if a and abs(r - color[0]) <= tol and abs(g - color[1]) <= tol and abs(b - color[2]) <= tol:
                px[x, y] = (r, g, b, 0)
    return img


def remove_background(img: Image.Image, mode: str, tol: int) -> Image.Image:
    img = img.convert("RGBA")
    if mode == "none":
        return img
    w, h = img.size
    corners = [img.getpixel(p)[:3] for p in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1))]
    if mode == "checker":
        # key both checker tones: the two most-different corner-adjacent samples
        samples = {img.getpixel((x, y))[:3] for x in (0, min(24, w - 1)) for y in (0, min(24, h - 1))}
        for c in samples:
            img = _key_color(img, c, tol)
        return img
    # auto: if all corners agree (within tol), chroma-key that color
    base = corners[0]
    if all(all(abs(c[i] - base[i]) <= tol for i in range(3)) for c in corners):
        img = _key_color(img, base, tol)
    else:
        # disagreeing corners usually mean a baked checkerboard — key light+dark grays
        for c in set(corners):
            img = _key_color(img, c, tol)
    return img


def spritify(src: str, dst: str, height: int, colors: int, bg: str, tol: int) -> tuple:
    img = Image.open(src)
    img = remove_background(img, bg, tol)
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    # quantize BEFORE downscale so the palette decision happens at detail scale;
    # keep alpha out of the quantizer (quantize RGB, reattach mask)
    alpha = img.split()[3]
    rgb = img.convert("RGB").quantize(colors=colors, dither=Image.Dither.NONE).convert("RGB")
    img = Image.merge("RGBA", (*rgb.split(), alpha))
    scale = height / img.height
    size = (max(1, round(img.width * scale)), height)
    img = img.resize(size, Image.Resampling.NEAREST)
    img.save(dst)
    return img.size


def self_test() -> int:
    import tempfile, os
    with tempfile.TemporaryDirectory() as td:
        src, dst = os.path.join(td, "s.png"), os.path.join(td, "d.png")
        canvas = Image.new("RGBA", (400, 600), (255, 255, 255, 255))
        # a triangle, so the cropped sprite's top-right corner must be transparent
        for y in range(100, 500):
            width = (y - 100) // 4
            for x in range(150, 150 + max(1, width)):
                canvas.putpixel((x, y), (120 + (x % 40), 90, 60, 255))
        canvas.save(src)
        size = spritify(src, dst, height=96, colors=16, bg="auto", tol=24)
        out = Image.open(dst).convert("RGBA")
        corner_alpha = out.getpixel((out.width - 1, 0))[3]
        px = out.load()
        n_colors = len({px[x, y] for y in range(out.height) for x in range(out.width) if px[x, y][3]})
        ok = size[1] == 96 and corner_alpha == 0 and n_colors <= 17
        print(f"self-test: size={size} corner_alpha={corner_alpha} colors={n_colors} -> "
              f"{'PASS' if ok else 'FAIL'}")
        return 0 if ok else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src", nargs="?")
    ap.add_argument("dst", nargs="?")
    ap.add_argument("--height", type=int, default=96)
    ap.add_argument("--colors", type=int, default=32)
    ap.add_argument("--bg", choices=["auto", "checker", "none"], default="auto")
    ap.add_argument("--tol", type=int, default=24)
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if not a.src or not a.dst:
        ap.error("src and dst required (or --self-test)")
    size = spritify(a.src, a.dst, a.height, a.colors, a.bg, a.tol)
    print(f"spritified {a.src} -> {a.dst} @ {size[0]}x{size[1]}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
