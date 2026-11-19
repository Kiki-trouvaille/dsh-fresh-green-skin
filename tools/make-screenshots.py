"""Render README screenshots (1280px wide JPEG) from the preview PNGs."""

import pathlib

from PIL import Image

WS = pathlib.Path(r"C:\Users\Admin1\Documents\deepseek-harness\default-workspace")
PREVIEW = WS / "skin-preview"
OUT = WS / "plugins" / "dsh-fresh-green-skin" / "screenshot"

JOBS = [
    ("fresh-green-light.png", "light.jpg"),
    ("fresh-green-dark.png", "dark.jpg"),
    ("settings-wallpaper-row.png", "settings.jpg"),
]


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    for source_name, target_name in JOBS:
        source = PREVIEW / source_name
        if not source.exists():
            raise SystemExit(f"missing {source}")
        image = Image.open(source).convert("RGB")
        width = 1280
        height = round(image.height * width / image.width)
        image = image.resize((width, height), Image.LANCZOS)
        target = OUT / target_name
        image.save(target, "JPEG", quality=84, optimize=True)
        print(f"{target.name}: {image.size[0]}x{image.size[1]} {target.stat().st_size}B")


if __name__ == "__main__":
    main()
