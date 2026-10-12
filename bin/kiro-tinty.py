#!/usr/bin/env python3
"""Set the Kiro IDE color theme from the scheme tinty currently has applied.

The Tinted VSCode extension registers themes whose labels equal tinty scheme
ids (for example base24-wild-cherry), so the current scheme id is written
straight into workbench.colorTheme; no name mapping is needed. Kiro IDE runs on
the Windows side, so its settings path is resolved from WSL via cmd.exe and
wslpath, which works for any user. Off WSL, or when Kiro is absent, this is a
no-op.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path


def tinty_current() -> str:
    """Return the scheme id that tinty currently has applied."""
    out = subprocess.run(
        ["tinty", "current"], capture_output=True, text=True, check=True
    )
    return out.stdout.strip()


def kiro_settings_path() -> Path | None:
    """Resolve the Windows Kiro user settings.json from WSL.

    Returns None off WSL or when the path cannot be resolved.
    """
    if not os.environ.get("WSL_DISTRO_NAME"):
        return None
    try:
        appdata = subprocess.run(
            ["cmd.exe", "/c", "echo %APPDATA%"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
        win_path = subprocess.run(
            ["wslpath", appdata], capture_output=True, text=True, check=True
        ).stdout.strip()
    except subprocess.CalledProcessError:
        return None
    if not win_path:
        return None
    return Path(win_path) / "Kiro" / "User" / "settings.json"


def main() -> int:
    scheme = tinty_current()
    path = kiro_settings_path()
    if path is None or not path.exists():
        return 0  # not on WSL, or Kiro not installed: nothing to do

    data = json.loads(path.read_text(encoding="utf-8"))
    if data.get("workbench.colorTheme") == scheme:
        return 0  # already correct: avoid a needless write

    data["workbench.colorTheme"] = scheme
    path.write_text(json.dumps(data, indent=4) + "\n", encoding="utf-8")
    print(f"kiro theme -> {scheme}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
