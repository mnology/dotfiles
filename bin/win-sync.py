#!/usr/bin/env python3
"""Sync tracked files between the dotfiles repo (WSL) and Windows paths.

Symlinks across the WSL/Windows boundary are unreliable, so files listed in
modern/sync/win-map.toml are copied. Directions are explicit; there is no
automatic merge.

  win-sync.py push     copy repo -> Windows (install direction)
  win-sync.py pull     copy Windows -> repo (capture Windows-app edits)
  win-sync.py status   report which side differs

Windows targets use %APPDATA% / %USERPROFILE%, resolved from WSL via cmd.exe
and wslpath. Off WSL this is a no-op.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAP = REPO / "modern/sync/win-map.toml"


def win_env(var: str) -> str | None:
    """Resolve a Windows env var (e.g. APPDATA) to a WSL path, or None.

    One-shot command, so a blocking run is correct. Surface the child's stderr
    on failure rather than swallowing it.
    """
    try:
        raw = subprocess.run(
            ["cmd.exe", "/c", f"echo %{var}%"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    except FileNotFoundError:
        return None  # not on WSL / no cmd.exe interop
    except subprocess.CalledProcessError as err:
        print(
            f"win-sync: cmd.exe %{var}% failed: {err.stderr.strip()}",
            file=sys.stderr,
        )
        return None
    if not raw or raw.startswith("%"):
        return None  # var unset: cmd echoes the literal %VAR%
    try:
        return subprocess.run(
            ["wslpath", raw], capture_output=True, text=True, check=True
        ).stdout.strip()
    except subprocess.CalledProcessError as err:
        print(
            f"win-sync: wslpath {raw!r} failed: {err.stderr.strip()}",
            file=sys.stderr,
        )
        return None


def resolve_win(win: str) -> Path | None:
    """Expand a %VAR%/... template to a concrete WSL-visible path."""
    for var in ("APPDATA", "USERPROFILE"):
        token = f"%{var}%"
        if win.startswith(token):
            base = win_env(var)
            return None if base is None else Path(base + win[len(token):])
    return None


def load_pairs() -> list[tuple[Path, Path]]:
    """Return (repo_path, win_path) pairs whose Windows side resolves."""
    data = tomllib.loads(MAP.read_text(encoding="utf-8"))
    pairs: list[tuple[Path, Path]] = []
    for entry in data.get("file", []):
        win = resolve_win(entry["win"])
        if win is not None:
            pairs.append((REPO / entry["repo"], win))
    return pairs


def same(a: Path, b: Path) -> bool:
    """True when both files exist and their bytes match."""
    return a.exists() and b.exists() and a.read_bytes() == b.read_bytes()


def copy(src: Path, dst: Path) -> None:
    """Copy src to dst, backing up a differing dst first."""
    dst.parent.mkdir(parents=True, exist_ok=True)
    if dst.exists() and not same(src, dst):
        shutil.copy2(dst, dst.with_suffix(dst.suffix + ".pre-winsync"))
    shutil.copy2(src, dst)


def cmd_push(pairs: list[tuple[Path, Path]]) -> int:
    for repo, win in pairs:
        if not repo.exists():
            print(f"skip (no repo file): {repo}")
            continue
        copy(repo, win)
        print(f"push {repo.name} -> {win}")
    return 0


def cmd_pull(pairs: list[tuple[Path, Path]]) -> int:
    for repo, win in pairs:
        if not win.exists():
            print(f"skip (no windows file): {win}")
            continue
        copy(win, repo)
        print(f"pull {win} -> {repo.name}")
    return 0


def cmd_status(pairs: list[tuple[Path, Path]]) -> int:
    for repo, win in pairs:
        if not win.exists():
            state = "windows-missing"
        elif not repo.exists():
            state = "repo-missing"
        elif same(repo, win):
            state = "in-sync"
        else:
            state = "differs"
        print(f"{state:16} {repo.name}")
    return 0


def main(argv: list[str]) -> int:
    if not MAP.exists():
        print(f"no map: {MAP}", file=sys.stderr)
        return 1
    commands = {"push": cmd_push, "pull": cmd_pull, "status": cmd_status}
    if len(argv) != 1 or argv[0] not in commands:
        print("usage: win-sync.py {push|pull|status}", file=sys.stderr)
        return 2
    pairs = load_pairs()
    if not pairs:
        print("no resolvable Windows targets (not on WSL?)")
        return 0
    return commands[argv[0]](pairs)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
