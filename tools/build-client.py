"""Generate client.js from client.js.tpl plus the wallpaper presets.

The plugin's client entry is a plain browser script, so wallpapers have to
travel with it: every photo in assets/presets is downscaled and inlined as a
WebP data URI, gradients are inlined as plain CSS. The list and its order come
from assets/presets/manifest.json — the first entry is the default wallpaper.

Usage:
    python tools/build-client.py

To ship another built-in wallpaper: drop the image into assets/presets, add an
entry to manifest.json, run this script, then reload the DSH window.
"""

import base64
import io
import json
import pathlib

from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent
ASSETS = ROOT / "assets"
PRESETS_DIR = ASSETS / "presets"
MANIFEST = PRESETS_DIR / "manifest.json"
WALL = ASSETS / "wallpaper.webp"
TPL = ROOT / "client.js.tpl"
OUT = ROOT / "client.js"
QUALITY = 78
MAX_WIDTH = 1920
IMAGE_SUFFIXES = {".png", ".jpg", ".jpeg", ".webp"}


def encode_photo(path: pathlib.Path) -> tuple[str, bytes]:
    image = Image.open(path).convert("RGB")
    if image.width > MAX_WIDTH:
        height = round(image.height * MAX_WIDTH / image.width)
        image = image.resize((MAX_WIDTH, height), Image.LANCZOS)
    buffer = io.BytesIO()
    image.save(buffer, "WEBP", quality=QUALITY, method=6)
    data = buffer.getvalue()
    return base64.b64encode(data).decode("ascii"), data


def build_presets() -> list[dict[str, str]]:
    if not MANIFEST.exists():
        raise SystemExit(f"missing {MANIFEST}")

    entries = json.loads(MANIFEST.read_text(encoding="utf-8"))
    presets: list[dict[str, str]] = []
    for entry in entries:
        preset_id = entry["id"]
        label = entry["label"]
        if "css" in entry:
            presets.append({"id": preset_id, "label": label, "value": entry["css"]})
            continue
        source = PRESETS_DIR / entry["file"]
        if not source.exists():
            raise SystemExit(f"missing preset image {source}")
        b64, data = encode_photo(source)
        if not presets:
            WALL.write_bytes(data)
            print(f"default wallpaper {source.name} webp={len(data)}B base64={len(b64)}B")
        presets.append(
            {"id": preset_id, "label": label, "value": f'url("data:image/webp;base64,{b64}")'}
        )
    if not presets:
        raise SystemExit("manifest.json lists no presets")
    return presets


def js_literal(presets: list[dict[str, str]]) -> str:
    lines = ["["]
    for preset in presets:
        lines.append(
            "  { id: %s, label: %s, value: %s },"
            % (
                json.dumps(preset["id"], ensure_ascii=False),
                json.dumps(preset["label"], ensure_ascii=False),
                json.dumps(preset["value"], ensure_ascii=False),
            )
        )
    lines.append("]")
    return "\n".join(lines)


def main() -> None:
    presets = build_presets()
    template = TPL.read_text(encoding="utf-8")
    if "__PRESETS__" not in template:
        raise SystemExit("client.js.tpl has no __PRESETS__ placeholder")

    OUT.write_text(template.replace("__PRESETS__", js_literal(presets)), encoding="utf-8")
    print(f"presets: {', '.join(p['id'] for p in presets)}")
    print(f"wrote {OUT} ({OUT.stat().st_size}B)")


if __name__ == "__main__":
    main()
