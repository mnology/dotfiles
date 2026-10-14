#!/usr/bin/env python3
"""Sync the GNOME desktop accent to the scheme tinty currently has applied.

It resolves the tinted-shell script for the current scheme (via `tinty
current`), picks the scheme's dominant accent the same way the starship hook
does (the highest-saturation hue-bearing base role), and maps that hue to the
nearest GNOME enum accent by angular hue distance. A nearly achromatic dominant
maps to 'slate', GNOME's neutral accent.

It writes the accent with `gsettings set org.gnome.desktop.interface
accent-color <enum>` (always one of ten valid enum values, so it cannot break
the Appearance panel the way a CSS overlay can), and also sets icon-theme and
gtk-theme to the matching Yaru dark variant so folder icons and GTK widgets
track the scheme too. The icon/gtk themes are only changed when the matching
Yaru variant is installed; otherwise it degrades to setting the accent alone.

Exit 0 on any miss: a tinty hook must not break the apply chain.
"""

from __future__ import annotations

import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

# tinted-shell colorNN -> base role name. Same mapping the starship hook uses;
# holds for base16 and base24.
COLOR_TO_ROLE = {
    "color00": "base00",
    "color01": "base08",
    "color02": "base0B",
    "color03": "base0A",
    "color04": "base0D",
    "color05": "base0E",
    "color06": "base0C",
    "color07": "base05",
    "color08": "base03",
    "color15": "base07",
    "color16": "base09",
    "color17": "base0F",
    "color18": "base01",
    "color19": "base02",
    "color20": "base04",
    "color21": "base06",
}

# Hue-bearing roles, in base order (base0F is a dim duplicate, left out), same
# candidate set the starship hook ranks.
ACCENT_ROLES = ("base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E")

# A dominant accent below this saturation is treated as achromatic -> slate.
ACHROMATIC_SAT = 0.15

# GNOME libadwaita accent enum -> canonical hex. The enum is the full set of
# values `gsettings range org.gnome.desktop.interface accent-color` reports.
GNOME_ACCENTS = {
    "blue": "#3584e4",
    "teal": "#2190a4",
    "green": "#3a944a",
    "yellow": "#c88800",
    "orange": "#ed5b00",
    "red": "#e62d42",
    "pink": "#d56199",
    "purple": "#9141ac",
    "slate": "#6f8396",
    "brown": "#986a44",
}

# GNOME accent enum -> Yaru dark variant for icon-theme/gtk-theme. Yaru does not
# ship a variant per GNOME enum, so a few are nearest matches by hue family:
# teal -> prussiangreen, green -> sage, orange and brown -> wartybrown (Yaru has
# no true orange), pink -> magenta, slate -> the neutral default Yaru-dark. All
# targets are confirmed installed under /usr/share/{themes,icons}.
GNOME_TO_YARU = {
    "blue": "Yaru-blue-dark",
    "teal": "Yaru-prussiangreen-dark",
    "green": "Yaru-sage-dark",
    "yellow": "Yaru-yellow-dark",
    "orange": "Yaru-wartybrown-dark",
    "red": "Yaru-red-dark",
    "pink": "Yaru-magenta-dark",
    "purple": "Yaru-purple-dark",
    "slate": "Yaru-dark",
    "brown": "Yaru-wartybrown-dark",
}

GSETTINGS_SCHEMA = "org.gnome.desktop.interface"
ACCENT_KEY = "accent-color"
ICON_KEY = "icon-theme"
GTK_KEY = "gtk-theme"


def _hue_sat(hex_color: str) -> tuple[float, float]:
    """Return (hue 0-360, saturation 0-1) of #rrggbb via HSV."""
    red, green, blue = (int(hex_color[i : i + 2], 16) / 255.0 for i in (1, 3, 5))
    high, low = max(red, green, blue), min(red, green, blue)
    span = high - low
    sat = 0.0 if high == 0 else span / high
    if span == 0:
        hue = 0.0
    elif high == red:
        hue = 60 * (((green - blue) / span) % 6)
    elif high == green:
        hue = 60 * (((blue - red) / span) + 2)
    else:
        hue = 60 * (((red - green) / span) + 4)
    return hue, sat


def _hue_distance(a: float, b: float) -> float:
    """Shortest angular distance between two hues, in degrees (0-180)."""
    diff = abs(a - b) % 360
    return min(diff, 360 - diff)


def _yaru_installed(variant: str) -> bool:
    """True if the Yaru variant exists as both a GTK theme and an icon theme.

    Checks the system and per-user search paths. Requiring both avoids setting
    an icon theme whose matching GTK theme is absent (or vice versa), which
    would leave the desktop half-themed.
    """
    data_dirs = [
        Path("/usr/share"),
        Path("/usr/local/share"),
        Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share")),
        Path.home() / ".themes",
        Path.home() / ".icons",
    ]
    has_theme = any((d / "themes" / variant).is_dir() or (d / variant).is_dir() for d in data_dirs)
    has_icons = any((d / "icons" / variant).is_dir() or (d / variant).is_dir() for d in data_dirs)
    return has_theme and has_icons


def read_palette(theme_file: Path) -> dict[str, str]:
    """Parse colorNN="RR/GG/BB" lines into a {base role: #rrggbb} map."""
    pattern = re.compile(r'(color\d\d)="([0-9A-Fa-f]{2})/([0-9A-Fa-f]{2})/([0-9A-Fa-f]{2})"')
    palette: dict[str, str] = {}
    for line in theme_file.read_text().splitlines():
        match = pattern.search(line)
        if not match:
            continue
        role = COLOR_TO_ROLE.get(match.group(1))
        if role is not None:
            palette[role] = f"#{match.group(2)}{match.group(3)}{match.group(4)}".lower()
    return palette


def dominant_accent(palette: dict[str, str]) -> str | None:
    """The highest-saturation hue-bearing accent, matching the starship hook."""
    accents = [palette[r] for r in ACCENT_ROLES if r in palette]
    if not accents:
        return None
    return max(accents, key=lambda c: _hue_sat(c)[1])


def nearest_gnome_accent(hex_color: str) -> str:
    """Map a hex accent to the nearest GNOME enum accent by hue distance."""
    hue, sat = _hue_sat(hex_color)
    if sat < ACHROMATIC_SAT:
        return "slate"
    chromatic = ((name, hx) for name, hx in GNOME_ACCENTS.items() if name != "slate")
    return min(chromatic, key=lambda item: _hue_distance(hue, _hue_sat(item[1])[0]))[0]


def tinty_shell_script() -> Path | None:
    """Resolve the tinted-shell .sh for the scheme tinty currently has applied.

    This hook is chained inside another item's hook (tinted-wezterm), so
    TINTY_THEME_FILE_PATH points at that item's theme file (a wezterm .toml),
    not the tinted-shell script this parser expects. Derive the correct path
    from `tinty current` instead, exactly as the sibling starship hook does.
    Returns None if it cannot be resolved.
    """
    try:
        scheme = subprocess.run(
            ["tinty", "current"], capture_output=True, text=True, check=True
        ).stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None
    if not scheme:
        return None
    data = (
        Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
        / "tinted-theming"
        / "tinty"
        / "repos"
        / "tinted-shell"
        / "scripts"
    )
    script = data / f"{scheme}.sh"
    return script if script.is_file() else None


def main() -> int:
    theme_file = tinty_shell_script()
    if theme_file is None:
        return 0
    if shutil.which("gsettings") is None:
        return 0

    palette = read_palette(theme_file)
    accent_hex = dominant_accent(palette)
    if accent_hex is None:
        return 0

    enum_value = nearest_gnome_accent(accent_hex)
    yaru_variant = GNOME_TO_YARU[enum_value]

    # accent-color is always safe (enum-validated by gsettings). icon-theme and
    # gtk-theme are only set when the Yaru variant is actually installed, so a
    # missing theme degrades to "accent only" instead of blanking the icons.
    updates = [(ACCENT_KEY, enum_value)]
    if _yaru_installed(yaru_variant):
        updates.append((ICON_KEY, yaru_variant))
        updates.append((GTK_KEY, yaru_variant))

    for key, value in updates:
        try:
            subprocess.run(
                ["gsettings", "set", GSETTINGS_SCHEMA, key, value],
                check=True,
                timeout=10,
            )
        except (subprocess.SubprocessError, OSError) as exc:
            print(f"gnome-accent-tinty: could not set {key} ({exc})", file=sys.stderr)
            return 0

    print(f"gnome accent -> {enum_value} / {yaru_variant} (from {accent_hex})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
