#!/usr/bin/env python3
"""Check that every shipped icon is usable and outline/fill changes its shape."""

from pathlib import Path
import subprocess


icons = Path(__file__).resolve().parents[1] / "icons"


def shape(path):
    # Normalize alpha before comparing: a merely dimmed copy has the same mask.
    pixels = subprocess.check_output([
        "magick", str(path), "-alpha", "extract", "-resize", "20x18!",
        "-threshold", "10%", "-depth", "8", "gray:-",
    ])
    assert len(pixels) == 20 * 18, path
    return bytes(value > 0 for value in pixels)


for family in "ABC":
    for device in ("Speaker", "Headphones", "Mouse", "Keyboard"):
        base = icons / f"Menu{family}{device}"
        for variant in ("", "Filled", "Outline"):
            path = base.with_name(base.name + variant + ".png")
            assert path.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"), path
            assert any(shape(path)), path

        filled = shape(base.with_name(base.name + "Filled.png"))
        outline = shape(base.with_name(base.name + "Outline.png"))
        changed_pixels = sum(a != b for a, b in zip(filled, outline))
        assert changed_pixels >= 25, (base.name, changed_pixels)

print("Icon artwork: OK")
