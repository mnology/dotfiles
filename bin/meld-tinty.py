#!/usr/bin/env python3
"""Generate a Meld style scheme from the palette tinty currently has applied.

Reads the active scheme from ``tinty current``, maps its base16/base24 slots onto
GtkSourceView style names through a declarative table, writes the scheme into
Meld's user styles directory, and selects it via gsettings.
"""

from __future__ import annotations

import itertools
import os
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import TYPE_CHECKING, Final

import yaml

if TYPE_CHECKING:
    from collections.abc import Mapping

DATA_DIR: Final = Path.home() / ".local/share/tinted-theming/tinty"


def _xdg_data_home() -> Path:
    """Return $XDG_DATA_HOME, or its default ~/.local/share."""
    env = os.environ.get("XDG_DATA_HOME")
    return Path(env) if env else Path.home() / ".local/share"


# Meld loads schemes through GtkSource.StyleSchemeManager.get_default(), which
# scans $XDG_DATA_HOME/gtksourceview-<ver>/styles. Meld links GtkSource 4, so
# write there. A copy in meld/styles alone is NOT on the default search path.
STYLES_DIR: Final = _xdg_data_home() / "gtksourceview-4" / "styles"
SCHEME_ID: Final = "tinty"
SCHEME_NAME: Final = "Tinty"
BACKGROUND_SLOT: Final = "base00"
SLOTS: Final = frozenset(f"base{n:02X}" for n in range(16))
HEX_COLOR: Final = re.compile(r"#[0-9a-f]{6}")
LINE_TINT: Final = 0.25
INLINE_TINT: Final = 0.4


class MeldTintyError(Exception):
    """Raised when the tinty palette cannot be turned into a Meld scheme."""


@dataclass(frozen=True, slots=True)
class Style:
    """One GtkSourceView style, expressed in palette slots rather than colors.

    Attributes:
        fg: Palette slot for the foreground, if any.
        bg: Palette slot for the background, if any.
        tint: When set, blend ``bg`` into the scheme background with this weight.
        italic: Render the text in italics.
    """

    fg: str | None = None
    bg: str | None = None
    tint: float | None = None
    italic: bool = False

    def attributes(self, palette: Mapping[str, str]) -> dict[str, str]:
        """Resolve this style against a palette.

        Args:
            palette: Slot name to ``#rrggbb`` color.

        Returns:
            XML attribute name to value, omitting anything unset.
        """
        fg = palette[self.fg] if self.fg else None
        bg = palette[self.bg] if self.bg else None
        if bg and self.tint is not None:
            bg = blend(bg, palette[BACKGROUND_SLOT], self.tint)
        pairs = {"foreground": fg, "background": bg, "italic": "true" if self.italic else None}
        return {key: value for key, value in pairs.items() if value}


STYLES: Final[Mapping[str, Style]] = MappingProxyType(
    {
        "text": Style(fg="base05", bg="base00"),
        "selection": Style(bg="base02"),
        "cursor": Style(fg="base05"),
        "current-line": Style(bg="base01"),
        "line-numbers": Style(fg="base03", bg="base00"),
        "def:comment": Style(fg="base03", italic=True),
        "def:string": Style(fg="base0B"),
        "def:constant": Style(fg="base09"),
        "def:number": Style(fg="base09"),
        "def:keyword": Style(fg="base0E"),
        "def:type": Style(fg="base0A"),
        "def:function": Style(fg="base0D"),
        "def:identifier": Style(fg="base08"),
        "meld:insert": Style(bg="base0B", tint=LINE_TINT),
        "meld:replace": Style(bg="base0D", tint=LINE_TINT),
        "meld:conflict": Style(bg="base08", tint=LINE_TINT),
        "meld:delete": Style(bg="base08", tint=LINE_TINT),
        "meld:inline": Style(bg="base0A", tint=INLINE_TINT),
        "meld:unimportant-text": Style(fg="base03"),
    },
)


def blend(color: str, backdrop: str, weight: float) -> str:
    """Mix two ``#rrggbb`` colors.

    Args:
        color: Color that receives ``weight``.
        backdrop: Color that receives ``1 - weight``.
        weight: Share of ``color`` in the result, from 0 to 1.

    Returns:
        The mixed color as ``#rrggbb``.
    """
    channels = (
        round(int(color[i : i + 2], 16) * weight + int(backdrop[i : i + 2], 16) * (1 - weight))
        for i in (1, 3, 5)
    )
    return "#" + "".join(f"{channel:02x}" for channel in channels)


def run_tool(argv: list[str]) -> str:
    """Run an external tool and return its stripped stdout.

    Args:
        argv: Command line; the first item is resolved on PATH.

    Returns:
        Standard output with surrounding whitespace removed.

    Raises:
        MeldTintyError: If the tool is missing or exits non-zero.
    """
    exe = shutil.which(argv[0])
    if exe is None:
        msg = f"{argv[0]} not found on PATH"
        raise MeldTintyError(msg)
    cmd = [exe, *argv[1:]]
    try:
        done = subprocess.run(cmd, capture_output=True, text=True, check=True)  # noqa: S603
    except subprocess.CalledProcessError as err:
        msg = f"{argv[0]} failed: {err.stderr.strip()}"
        raise MeldTintyError(msg) from err
    return done.stdout.strip()


def parse_scheme_id(scheme_id: str) -> tuple[str, str]:
    """Split ``base24-hivacruz`` into ``("base24", "hivacruz")``.

    Args:
        scheme_id: Value printed by ``tinty current``.

    Returns:
        The color system and the scheme slug.

    Raises:
        MeldTintyError: If the id has no system prefix.
    """
    system, sep, slug = scheme_id.partition("-")
    if not (sep and slug):
        msg = f"unexpected tinty scheme id: {scheme_id!r}"
        raise MeldTintyError(msg)
    return system, slug


def find_scheme_file(system: str, slug: str) -> Path:
    """Locate a scheme's YAML file, preferring custom schemes over synced ones.

    Args:
        system: Color system directory name, such as ``base24``.
        slug: Scheme file stem.

    Returns:
        Path to the first matching YAML file.

    Raises:
        MeldTintyError: If no file matches.
    """
    roots = (DATA_DIR / "custom-schemes" / system, DATA_DIR / "repos" / "schemes" / system)
    hits = itertools.chain.from_iterable(
        root.rglob(f"{slug}.yaml") for root in roots if root.is_dir()
    )
    found = next(hits, None)
    if found is None:
        msg = f"no {slug}.yaml in any of: {', '.join(str(root) for root in roots)}"
        raise MeldTintyError(msg)
    return found


def load_palette(path: Path) -> dict[str, str]:
    """Read and validate a scheme's palette.

    Args:
        path: Scheme YAML file.

    Returns:
        Slot name (``base00``..``base0F``) to lowercase ``#rrggbb``.

    Raises:
        MeldTintyError: If the file is malformed or lacks a slot.
    """
    doc = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(doc, dict):
        msg = f"{path} is not a YAML mapping"
        raise MeldTintyError(msg)
    raw = doc.get("palette", doc)
    palette = {
        key[:4] + key[4:].upper(): "#" + str(value).lstrip("#").lower()
        for key, value in raw.items()
        if str(key).startswith("base")
    }
    missing = SLOTS - palette.keys()
    invalid = [slot for slot, color in palette.items() if not HEX_COLOR.fullmatch(color)]
    if missing or invalid:
        msg = f"{path}: missing slots {sorted(missing)}, invalid colors {sorted(invalid)}"
        raise MeldTintyError(msg)
    return palette


def render_style(name: str, attributes: Mapping[str, str]) -> str:
    """Render one ``<style/>`` element.

    Args:
        name: GtkSourceView style name.
        attributes: Attribute name to value.

    Returns:
        A single indented XML line.
    """
    attrs = "".join(f' {key}="{value}"' for key, value in attributes.items())
    return f'  <style name="{name}"{attrs}/>'


def render_scheme(palette: Mapping[str, str]) -> str:
    """Render the complete style-scheme document.

    Args:
        palette: Slot name to ``#rrggbb``.

    Returns:
        The XML text.
    """
    body = "\n".join(render_style(name, spec.attributes(palette)) for name, spec in STYLES.items())
    # Use the runtime attribute "name" (not "_name"; that underscore form is a
    # gettext marker for .in source files and GtkSourceView ignores it at
    # runtime). parent-scheme="classic" inherits the base style definitions we
    # do not set here, so unstyled elements still render correctly.
    return (
        '<?xml version="1.0" encoding="UTF-8"?>\n'
        f'<style-scheme id="{SCHEME_ID}" name="{SCHEME_NAME}" version="1.0" parent-scheme="classic">\n'
        f"{body}\n"
        "</style-scheme>\n"
    )


def write_scheme(xml: str) -> Path:
    """Write the scheme into Meld's user styles directory.

    Args:
        xml: Rendered style-scheme document.

    Returns:
        The file that was written.
    """
    STYLES_DIR.mkdir(parents=True, exist_ok=True)
    target = STYLES_DIR / f"{SCHEME_ID}.style-scheme.xml"
    target.write_text(xml, encoding="utf-8")
    return target


def select_in_meld() -> None:
    """Make Meld use the generated scheme."""
    run_tool(["gsettings", "set", "org.gnome.meld", "style-scheme", SCHEME_ID])


def main() -> int:
    """Generate and select the scheme.

    Returns:
        Process exit code: 0 on success, 1 if the scheme could not be written.
    """
    try:
        scheme_id = run_tool(["tinty", "current"])
        palette = load_palette(find_scheme_file(*parse_scheme_id(scheme_id)))
        write_scheme(render_scheme(palette))
    except (MeldTintyError, OSError, yaml.YAMLError) as err:
        sys.stderr.write(f"meld-tinty: {err}\n")
        return 1
    try:
        select_in_meld()
    except MeldTintyError as err:
        sys.stderr.write(f"meld-tinty: scheme written but not selected: {err}\n")
    sys.stderr.write(f"meld scheme -> {scheme_id}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
