#!/usr/bin/env python3
"""Generate the starship palette from the scheme tinty currently has applied.

tinty remaps the terminal ANSI slots per scheme, but a starship bar that names
ANSI colors ("blue", "bright-red") cannot reach the full base16/base24 ramp:
there is no true orange in the 16 ANSI slots, and a hardcoded light foreground
is unreadable on a light segment background. This script fixes both.

It reads the tinted-shell script tinty points at ($TINTY_THEME_FILE_PATH),
which exposes every base role as colorNN="RR/GG/BB" with a role comment, for
both base16 and base24 schemes. It builds a hex palette by base role, then for
each colored segment it picks the foreground (dark base00 or light base07) that
has the higher WCAG contrast against that segment background. The resolved
palette and per-segment foregrounds are written into a sentinel-delimited block
in a TEMPLATE starship config; the result is written to the live config that
starship reads ($STARSHIP_CONFIG). The template stays tracked and pristine; the
live file is generated and untracked.

Exit 0 on any miss: a tinty hook must not break the apply chain.
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
from pathlib import Path

# tinted-shell colorNN -> base role name. Holds for base16 and base24; the
# bright slots (color09-14) mirror the base colors on base16 and use the
# extended base10-base17 values on base24, which is the correct degradation.
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

# Sentinel block the template carries; everything between is regenerated.
BEGIN = "# >>> TINTY PALETTE >>>"
END = "# <<< TINTY PALETTE <<<"

# Neutral surface segments keep fixed roles (docker/conda, time). Only the
# hue-bearing segments adapt to the scheme; the tail stays calm by design.
# fg key names avoid any "baseNN" substring: starship resolves a palette value
# that references another palette key, so "fg_on_base0A" would be read as a
# reference to base0A and the style would silently drop. "ink_*" names avoid it.
SURFACE_FG = {
    "base01": "ink_tool",  # surface: docker / conda
    "base00": "ink_time",  # darkest: time
}

_COLOR_RE = re.compile(
    r'^(color\d\d)="([0-9a-fA-F]{2})/([0-9a-fA-F]{2})/([0-9a-fA-F]{2})"'
)


def parse_palette(theme_sh: Path) -> dict[str, str]:
    """Map base role -> #rrggbb from the tinted-shell script."""
    palette: dict[str, str] = {}
    for line in theme_sh.read_text(encoding="utf-8").splitlines():
        match = _COLOR_RE.match(line.strip())
        if not match:
            continue
        key, red, green, blue = match.groups()
        role = COLOR_TO_ROLE.get(key)
        if role:
            palette[role] = f"#{red}{green}{blue}".lower()
    return palette


def _relative_luminance(hex_color: str) -> float:
    """WCAG relative luminance of #rrggbb, 0.0 (black) to 1.0 (white)."""
    channels = []
    for index in (1, 3, 5):
        value = int(hex_color[index : index + 2], 16) / 255.0
        linear = value / 12.92 if value <= 0.03928 else ((value + 0.055) / 1.055) ** 2.4
        channels.append(linear)
    red, green, blue = channels
    return 0.2126 * red + 0.7152 * green + 0.0722 * blue


def _contrast(fg: str, bg: str) -> float:
    """WCAG contrast ratio between two #rrggbb colors (1.0 to 21.0)."""
    light = _relative_luminance(fg)
    dark = _relative_luminance(bg)
    lighter, darker = max(light, dark), min(light, dark)
    return (lighter + 0.05) / (darker + 0.05)


def legible_fg(bg_hex: str, dark_hex: str, light_hex: str) -> str:
    """Return whichever of dark/light foreground reads better on bg."""
    if _contrast(light_hex, bg_hex) >= _contrast(dark_hex, bg_hex):
        return light_hex
    return dark_hex


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


# Accent roles that carry hue, in base order. base0f is usually a dim duplicate,
# so it is left out of the candidate set.
ACCENT_ROLES = ("base08", "base09", "base0A", "base0B", "base0C", "base0D", "base0E")

# Two hues closer than this (degrees) count as the same color; the second is
# skipped so adjacent segments never look near-identical.
HUE_DEDUP_DEGREES = 25.0

# Hue-bearing segment slots the template references, in bar order.
SEGMENT_SLOTS = ("seg1", "seg2", "seg3", "seg4")


def choose_segments(palette: dict[str, str]) -> list[str]:
    """Pick hex colors for the hue segments by the palette's own emphasis.

    Rank accents by saturation (the designer's intent for dominance), skip
    near-duplicate hues, take the top N, then order those by hue so the bar
    sweeps the wheel smoothly. Saturation is used as-is, so a pastel scheme
    yields a pastel bar. Falls back to ranked order if dedup leaves too few.
    """
    accents = [palette[r] for r in ACCENT_ROLES if r in palette]
    ranked = sorted(accents, key=lambda c: _hue_sat(c)[1], reverse=True)

    chosen: list[str] = []
    for color in ranked:
        hue = _hue_sat(color)[0]
        if all(_hue_distance(hue, _hue_sat(c)[0]) >= HUE_DEDUP_DEGREES for c in chosen):
            chosen.append(color)
        if len(chosen) == len(SEGMENT_SLOTS):
            break
    # Monochrome scheme: dedup starved the list. Fill from ranked, ignoring it.
    for color in ranked:
        if len(chosen) == len(SEGMENT_SLOTS):
            break
        if color not in chosen:
            chosen.append(color)

    return sorted(chosen, key=lambda c: _hue_sat(c)[0])


def _hue_distance(a: float, b: float) -> float:
    """Shortest angular distance between two hues, in degrees (0-180)."""
    diff = abs(a - b) % 360
    return min(diff, 360 - diff)


def build_block(palette: dict[str, str], segments: list[str]) -> str:
    """Render the [palettes.base24] block: every role plus per-segment fg.

    Role keys are emitted lowercase. starship lowercases a bg:/fg: reference
    when resolving it but stores palette keys case-sensitively, so an uppercase
    key like base0A is never matched and the color silently drops. `segments`
    is the chosen hue-bearing accents, computed once and shared with the tmux
    fragment so the prompt and status bar use the same colors.
    """
    dark = palette["base00"]
    light = palette["base07"]
    lines = [BEGIN, "[palettes.base24]"]
    for role in sorted(palette):
        lines.append(f'{role.lower()} = "{palette[role]}"')

    # Hue-bearing segments: chosen from the scheme's own accents by saturation
    # (designer emphasis), hue-ordered so the bar sweeps the wheel. Each gets a
    # stable seg<N> alias the template references, plus a contrast-picked ink.
    for slot, bg in zip(SEGMENT_SLOTS, segments):
        lines.append(f'{slot} = "{bg}"')
        lines.append(f'ink_{slot} = "{legible_fg(bg, dark, light)}"')

    # Neutral surface segments keep fixed roles; only their ink is resolved.
    for role, fg_key in SURFACE_FG.items():
        bg = palette.get(role)
        if bg:
            lines.append(f'{fg_key} = "{legible_fg(bg, dark, light)}"')
    lines.append(END)
    return "\n".join(lines)


# tmux status pills map to the shared segments by semantic role, not bar order.
# session = seg1, host = seg2, current window = seg4 (the attention pill, a
# distinct end-of-sweep hue). The clock stays a neutral surface, set in the
# status template, because ambient info should not compete with the accents.
def build_tmux_fragment(palette: dict[str, str], segments: list[str]) -> str:
    """Render tmux user-options the status template references.

    Emits @tinty_* options as #rrggbb plus a legible ink per pill, so the
    status bar uses the same scheme-derived accents as the starship prompt.
    """
    dark = palette["base00"]
    light = palette["base07"]
    seg = dict(zip(SEGMENT_SLOTS, segments))
    pills = {
        "session": seg.get("seg1", palette.get("base08", dark)),
        "host": seg.get("seg2", palette.get("base0A", dark)),
        "activity": seg.get("seg3", palette.get("base0C", dark)),
        "window": seg.get("seg4", palette.get("base0D", dark)),
    }
    # Two distinct surfaces. bar = base03: the window-list base, chosen to sit
    # clearly ABOVE the terminal bg (base00) so the bar has presence. base01 is
    # too close to base00 (often <1.1:1) and makes the bar vanish. clock =
    # base01: a recessed pill, darker than the bar, calm against the accents.
    bar = palette.get("base03", palette.get("base02", dark))
    clock = palette.get("base01", bar)
    # Divider for the thin arrow between inactive tabs (which share the bar
    # bg). base05 (main fg) gives a clearly visible vertical rule; base04 was
    # too faint against the bar (often <1.7:1).
    divider = palette.get("base05", palette.get("base06", bar))
    lines = [
        "# Generated by bin/starship-tinty.py. Do not edit; edit the generator.",
        f'set -g @tinty_bar_bg "{bar}"',
        f'set -g @tinty_bar_fg "{legible_fg(bar, dark, light)}"',
        f'set -g @tinty_divider "{divider}"',
    ]
    for name, bg in pills.items():
        lines.append(f'set -g @tinty_{name}_bg "{bg}"')
        lines.append(f'set -g @tinty_{name}_fg "{legible_fg(bg, dark, light)}"')
    lines.append(f'set -g @tinty_clock_bg "{clock}"')
    lines.append(f'set -g @tinty_clock_fg "{legible_fg(clock, dark, light)}"')
    return "\n".join(lines) + "\n"


def render(template: str, block: str) -> str | None:
    """Replace the sentinel block in the template with the generated block."""
    pattern = re.compile(re.escape(BEGIN) + r".*?" + re.escape(END), re.DOTALL)
    if not pattern.search(template):
        return None
    return pattern.sub(block, template)


def tinty_shell_script() -> Path | None:
    """Resolve the tinted-shell .sh for the scheme tinty currently has applied.

    The script is chained inside another item's hook, so TINTY_THEME_FILE_PATH
    points at that item's theme file (a wezterm .toml), not the shell script.
    Derive the correct path from `tinty current` instead, like the sibling
    *-tinty.py hooks do. Returns None if it cannot be resolved.
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
    theme_sh = tinty_shell_script()
    if theme_sh is None:
        return 0

    dotfiles = Path(__file__).resolve().parent.parent
    template_path = dotfiles / "starship.toml"
    live_path = Path(
        os.environ.get("STARSHIP_CONFIG")
        or (
            Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
            / "starship.generated.toml"
        )
    )

    # Refuse to write the tracked template, even if STARSHIP_CONFIG is wrong or
    # a stale symlink points back into the repo. The template is read-only here.
    if live_path.resolve() == template_path.resolve():
        print("starship-tinty: refusing to overwrite the template", file=sys.stderr)
        return 0

    palette = parse_palette(theme_sh)
    # base00 and base07 anchor the contrast decision; without them, do nothing.
    if "base00" not in palette or "base07" not in palette:
        return 0

    # Choose the adaptive accents once; share them with both outputs so the
    # prompt and the tmux status bar use identical scheme-derived colors.
    segments = choose_segments(palette)

    template = template_path.read_text(encoding="utf-8")
    result = render(template, build_block(palette, segments))
    if result is None:
        print("starship-tinty: no sentinel block in template", file=sys.stderr)
        return 0

    live_path.parent.mkdir(parents=True, exist_ok=True)
    if not (live_path.exists() and live_path.read_text(encoding="utf-8") == result):
        live_path.write_text(result, encoding="utf-8")
    print(f"starship palette -> {theme_sh.stem}", file=sys.stderr)

    # tmux status colors: write the shared fragment the status template reads.
    write_tmux_fragment(build_tmux_fragment(palette, segments))
    return 0


def write_tmux_fragment(fragment: str) -> None:
    """Write the tmux color fragment and reload it into a running server.

    No-op cleanly if tmux is absent or no server is running: the status bar is
    optional and must never break the theme-apply chain.
    """
    config_home = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
    path = config_home / "tmux" / "tinty-colors.conf"
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists() and path.read_text(encoding="utf-8") == fragment:
        pass
    else:
        path.write_text(fragment, encoding="utf-8")
    # Reload into the live server if one is running. refresh-client -S redraws
    # the status line immediately. Failure here is harmless (no server/display).
    try:
        subprocess.run(
            ["tmux", "source-file", str(path)], check=False, capture_output=True
        )
        subprocess.run(
            ["tmux", "refresh-client", "-S"], check=False, capture_output=True
        )
    except FileNotFoundError:
        pass


if __name__ == "__main__":
    sys.exit(main())
