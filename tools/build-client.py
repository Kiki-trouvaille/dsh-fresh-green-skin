"""Generate client.js from client.js.tpl + assets/wallpaper.webp.

The plugin's client entry is a plain browser script, so the wallpaper has to
travel with it: we inline a WebP data URI (q78 keeps client.js ~210 KB).

Usage:
    python tools/build-client.py
"""

import base64
import io
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "assets" / "wallpaper-src.png"
WALL = ROOT / "assets" / "wallpaper.webp"
TPL = ROOT / "client.js.tpl"
OUT = ROOT / "client.js"
QUALITY = 78


def main() -> None:
    if not SRC.exists():
        raise SystemExit(f"missing {SRC}: put the photo there first")

    image = Image.open(SRC).convert("RGB")
    buffer = io.BytesIO()
    image.save(buffer, "WEBP", quality=QUALITY, method=6)
    data = buffer.getvalue()
    WALL.write_bytes(data)
    b64 = base64.b64encode(data).decode("ascii")

    template = TPL.read_text(encoding="utf-8")
    if "__WALL_B64__" not in template:
        raise SystemExit("client.js.tpl has no __WALL_B64__ placeholder")

    OUT.write_text(template.replace("__WALL_B64__", b64), encoding="utf-8")
    print(f"wallpaper {image.size[0]}x{image.size[1]} webp={len(data)}B base64={len(b64)}B")
    print(f"wrote {OUT} ({OUT.stat().st_size}B)")


if __name__ == "__main__":
    main()
