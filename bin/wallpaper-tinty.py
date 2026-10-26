#!/usr/bin/env python3
"""Generate and apply a tinty scheme from the current GNOME desktop wallpaper.

Direction: wallpaper -> scheme (the inverse of gnome-accent-tinty.py, which
goes scheme -> desktop accent). Read the active wallpaper from gsettings, build
a base24 scheme from the image with `tinty generate-scheme`, force the darkest
sampled tone onto base00 (the generator picks the background anchor by cluster
weight, which can land on a muddy mid-tone), then apply it. The existing apply
hooks (starship, gnome-accent, ...) fire on apply, so the desktop accent and
icons follow for free.

Variant follows org.gnome.desktop.interface color-scheme. Slug is derived from
the wallpaper filename, so each wallpaper keeps its own scheme.

User override (model b): the user may apply any scheme by hand. On the next
wallpaper change this tool notices that `tinty current` is not the scheme it
last applied, flips to MANUAL mode, and backs off instead of stomping the
choice. `wallpaper-tinty auto` opts back in and re-derives from the wallpaper.

Subcommands:
  wallpaper-tinty            apply from wallpaper if mode=auto (service entry)
  wallpaper-tinty auto       opt back in, set mode=auto, regenerate now
  wallpaper-tinty manual     go dormant; keep the current scheme
  wallpaper-tinty now        force a one-shot regenerate regardless of mode
  wallpaper-tinty status     print mode and active scheme

Exit 0 on any miss: the systemd service must not wedge on a bad wallpaper.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse

from PIL import Image

# Wallpapers can be very large (100+ MP). We only sample a thumbnail, so the
# decompression-bomb guard is not useful here and would raise on big images.
# Disable it; the input is the user's own local wallpaper, not untrusted.
Image.MAX_IMAGE_PIXELS = None

BG_SCHEMA = "org.gnome.desktop.background"
IFACE_SCHEMA = "org.gnome.desktop.interface"
SLUG_PREFIX = "wallpaper"

_CACHE_DIR = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
MODE_FILE = _CACHE_DIR / "wallpaper-tinty-mode"   # 'auto' | 'manual'
LAST_FILE = _CACHE_DIR / "wallpaper-tinty-last"   # slug this tool last applied


# --- gsettings + wallpaper resolution ---------------------------------------

def _gsettings_get(schema: str, key: str) -> str | None:
    try:
        out = subprocess.run(
            ["gsettings", "get", schema, key],
            capture_output=True, text=True, check=True, timeout=10,
        ).stdout.strip()
    except (subprocess.SubprocessError, OSError):
        return None
    return out[1:-1] if len(out) >= 2 and out[0] == "'" and out[-1] == "'" else out


def current_variant() -> str:
    """'dark' or 'light' from color-scheme; default dark."""
    scheme = _gsettings_get(IFACE_SCHEMA, "color-scheme") or ""
    return "light" if "light" in scheme else "dark"


def wallpaper_path() -> Path | None:
    """Resolve the active wallpaper file. Prefer the dark URI in dark mode."""
    key = "picture-uri-dark" if current_variant() == "dark" else "picture-uri"
    uri = _gsettings_get(BG_SCHEMA, key) or _gsettings_get(BG_SCHEMA, "picture-uri")
    if not uri:
        return None
    path = Path(unquote(urlparse(uri).path)) if uri.startswith("file://") else Path(uri)
    return path if path.is_file() else None


# --- mode state --------------------------------------------------------------

def read_mode() -> str:
    """Current mode; default 'auto' when unset."""
    if MODE_FILE.is_file():
        return MODE_FILE.read_text().strip() or "auto"
    return "auto"


def write_mode(mode: str) -> None:
    MODE_FILE.parent.mkdir(parents=True, exist_ok=True)
    MODE_FILE.write_text(mode)


def last_applied_slug() -> str | None:
    return LAST_FILE.read_text().strip() if LAST_FILE.is_file() else None


def record_applied_slug(slug: str) -> None:
    LAST_FILE.parent.mkdir(parents=True, exist_ok=True)
    LAST_FILE.write_text(slug)


def tinty_current() -> str | None:
    try:
        out = subprocess.run(
            ["tinty", "current"], capture_output=True, text=True, check=True, timeout=10,
        ).stdout.strip()
    except (subprocess.SubprocessError, OSError):
        return None
    return out or None


# --- scheme generation -------------------------------------------------------

def slug_from_filename(path: Path) -> str:
    """Lower-case, hyphenated slug from the wallpaper stem (no whitespace/caps)."""
    stem = re.sub(r"[^a-z0-9]+", "-", path.stem.lower()).strip("-")
    return f"{SLUG_PREFIX}-{stem or 'current'}"


def darkest_tone(path: Path) -> str | None:
    """Darkest representative color as #rrggbb, by lowest max-channel (HSV value).

    Quantize to a small palette, then pick the entry with the lowest max-channel,
    giving a true dark anchor instead of the generator's cluster-weighted pick.
    """
    try:
        img = Image.open(path).convert("RGB")
    except (OSError, ValueError):
        return None
    img.thumbnail((200, 200))
    quant = img.quantize(colors=16, method=Image.Quantize.FASTOCTREE).convert("RGB")
    colors = quant.getcolors(maxcolors=4096) or []
    if not colors:
        return None
    _, (r, g, b) = min(colors, key=lambda c: max(c[1]))
    return f"#{r:02x}{g:02x}{b:02x}"


def _force_base00(slug: str, variant: str, dark_hex: str | None) -> None:
    """Rewrite base00 in the saved dark scheme to the image's darkest tone.

    Dark variant only; a light scheme wants a light background, so leave it.
    No-op if the file or the darkest tone is missing.
    """
    if variant != "dark" or dark_hex is None:
        return
    scheme_file = (
        Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        / "tinted-theming" / "tinty" / "custom-schemes" / "base24" / f"{slug}.yaml"
    )
    if not scheme_file.is_file():
        return
    text = scheme_file.read_text()
    new = re.sub(r"(?m)^(\s*base00:\s*)'[^']*'", rf"\1'{dark_hex}'", text)
    if new != text:
        scheme_file.write_text(new)


def generate_and_apply(path: Path) -> str | None:
    """Build, normalize, and apply a scheme from the wallpaper. Return the slug."""
    slug = slug_from_filename(path)
    variant = current_variant()
    name = path.stem.replace("-", " ").title()
    gen = subprocess.run(
        ["tinty", "generate-scheme", "--system", "base24", "--variant", variant,
         "--slug", slug, "--name", name,
         "--author", "wallpaper-tinty (generated)",
         "--description", f"base24 {variant} generated from wallpaper {path.name}",
         "--save", str(path)],
        capture_output=True, text=True,
    )
    if gen.returncode != 0:
        print(f"wallpaper-tinty: generate-scheme failed: {gen.stderr.strip()}", file=sys.stderr)
        return None

    _force_base00(slug, variant, darkest_tone(path))

    applied = subprocess.run(
        ["tinty", "apply", f"base24-{slug}"], capture_output=True, text=True,
    )
    if applied.returncode != 0:
        print(f"wallpaper-tinty: apply failed: {applied.stderr.strip()}", file=sys.stderr)
        return None
    record_applied_slug(f"base24-{slug}")
    print(f"wallpaper-tinty -> base24-{slug} ({variant}) from {path.name}")
    return slug


# --- entry points ------------------------------------------------------------

def run_from_wallpaper(force: bool) -> int:
    """Service entry. Respect mode and detect a manual override (model b)."""
    if not force and read_mode() == "manual":
        return 0  # dormant; user chose manual

    # Model b: if the active scheme is not the one we last set, the user applied
    # something by hand. Back off to manual instead of stomping it.
    if not force:
        current = tinty_current()
        last = last_applied_slug()
        if current is not None and last is not None and current != last:
            write_mode("manual")
            print(f"wallpaper-tinty: detected manual scheme '{current}'; "
                  f"switched to manual mode (run 'wallpaper-tinty auto' to resume)")
            return 0

    path = wallpaper_path()
    if path is None:
        return 0
    generate_and_apply(path)
    return 0


def cmd_status() -> int:
    print(f"mode:    {read_mode()}")
    print(f"current: {tinty_current() or '(unknown)'}")
    print(f"last set by wallpaper-tinty: {last_applied_slug() or '(none)'}")
    wp = wallpaper_path()
    print(f"wallpaper: {wp.name if wp else '(none)'}")
    return 0


def main(argv: list[str]) -> int:
    cmd = argv[0] if argv else ""
    if cmd in ("", "run"):
        return run_from_wallpaper(force=False)
    if cmd == "now":
        return run_from_wallpaper(force=True)
    if cmd == "auto":
        write_mode("auto")
        print("wallpaper-tinty: mode=auto; re-deriving from wallpaper")
        return run_from_wallpaper(force=True)
    if cmd == "manual":
        write_mode("manual")
        print("wallpaper-tinty: mode=manual; keeping current scheme")
        return 0
    if cmd == "status":
        return cmd_status()
    print(f"wallpaper-tinty: unknown command '{cmd}' "
          f"(run | auto | manual | now | status)", file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
