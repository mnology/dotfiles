#!/usr/bin/env python3
"""Generate each AI client's MCP config from the neutral single source.

Source of truth: agents/mcp/servers.json. Add a server there and run this
(via bootstrap). It propagates to every client, replacing only the custom
MCP servers and preserving everything else each client owns.

Ownership model (agreed): the neutral source owns the full set of CUSTOM MCP
servers. Per client:
  - Kiro  (~/.kiro/settings/mcp.json)                : replace `mcpServers`,
    keep any other top-level keys.
  - Cline (~/.cline/data/settings/cline_mcp_settings.json): same shape.
  - Goose (~/.config/goose/config.yaml)              : within `extensions`,
    replace only `type: stdio` entries; preserve `type: platform`/`builtin`
    and every non-extension key (providers, active_provider, ...).

No secrets are written: aws-mcp carries only the AWS profile name in env and
authenticates via SSO at runtime.

Idempotent. Safe to run repeatedly. Tolerant of Goose rewriting its own file.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any, NoReturn

try:
    import yaml  # PyYAML, for Goose's config.yaml
except ImportError:  # pragma: no cover - PyYAML absent only degrades Goose
    yaml = None  # type: ignore[assignment]

HOME = Path.home()
DOTFILES = Path(__file__).resolve().parent.parent
SOURCE = DOTFILES / "agents" / "mcp" / "servers.json"

KIRO_CFG = HOME / ".kiro" / "settings" / "mcp.json"
CLINE_CFG = HOME / ".cline" / "data" / "settings" / "cline_mcp_settings.json"
GOOSE_CFG = HOME / ".config" / "goose" / "config.yaml"


def die(msg: str) -> NoReturn:
    print(f"gen-mcp: {msg}", file=sys.stderr)
    raise SystemExit(1)


def load_source() -> list[dict[str, Any]]:
    """Read and validate the neutral server list."""
    if not SOURCE.is_file():
        die(f"source not found: {SOURCE}")
    data: Any = json.loads(SOURCE.read_text())
    servers = data.get("servers")
    if not isinstance(servers, list) or not servers:
        die("source has no 'servers' list")
    for s in servers:
        for key in ("name", "command", "args"):
            if key not in s:
                die(f"server entry missing '{key}': {s}")
    return servers


def to_mcpservers_shape(servers: list[dict[str, Any]]) -> dict[str, Any]:
    """Kiro/Cline native shape: the `mcpServers` object."""
    out: dict[str, Any] = {}
    for s in servers:
        entry: dict[str, Any] = {
            "command": s["command"],
            "args": list(s["args"]),
            "disabled": False,
        }
        if s.get("env"):
            entry["env"] = dict(s["env"])
        if s.get("timeout_ms"):
            entry["timeout"] = s["timeout_ms"]
            entry["transport"] = "stdio"
        out[s["name"]] = entry
    return out


def to_goose_stdio(servers: list[dict[str, Any]]) -> dict[str, Any]:
    """Goose native shape: `extensions` entries of type stdio.

    Goose stores timeout in SECONDS, cmd/args split, env map named `envs`.
    """
    out: dict[str, Any] = {}
    for s in servers:
        entry: dict[str, Any] = {
            "enabled": True,
            "type": "stdio",
            "name": s["name"],
            "cmd": s["command"],
            "args": list(s["args"]),
            "envs": dict(s.get("env") or {}),
            "bundled": False,
        }
        if s.get("timeout_ms"):
            entry["timeout"] = max(1, int(s["timeout_ms"] / 1000))
        out[s["name"]] = entry
    return out


def write_json_client(path: Path, servers: list[dict[str, Any]], label: str) -> None:
    """Replace `mcpServers`, preserve other top-level keys. Create if absent."""
    doc: dict[str, Any] = {}
    if path.is_file():
        doc = json.loads(path.read_text())
    doc["mcpServers"] = to_mcpservers_shape(servers)
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(doc, indent=2) + "\n")
    print(f"gen-mcp: wrote {label}: {path}")


def write_goose(path: Path, servers: list[dict[str, Any]]) -> None:
    """Merge stdio extensions into Goose config, preserving builtins + rest."""
    if yaml is None:
        print("gen-mcp: skip Goose: PyYAML not installed", file=sys.stderr)
        return
    if not path.is_file():
        die(f"goose config missing (run goose once first): {path}")
    doc = yaml.safe_load(path.read_text()) or {}
    exts = doc.get("extensions")
    if not isinstance(exts, dict):
        exts = {}
    # Preserve every extension Goose owns (platform/builtin). Drop only the
    # stdio entries we previously generated, then re-add the current source.
    preserved = {
        name: cfg
        for name, cfg in exts.items()
        if not (isinstance(cfg, dict) and cfg.get("type") == "stdio")
    }
    preserved.update(to_goose_stdio(servers))
    doc["extensions"] = preserved
    path.write_text(yaml.safe_dump(doc, sort_keys=False, default_flow_style=False))
    print(f"gen-mcp: wrote Goose: {path}")


# Client dispatch table (rule 2: behavior selected by data).
CLIENTS = {
    "kiro": lambda servers: write_json_client(KIRO_CFG, servers, "Kiro"),
    "cline": lambda servers: write_json_client(CLINE_CFG, servers, "Cline"),
    "goose": lambda servers: write_goose(GOOSE_CFG, servers),
}


def main(argv: list[str]) -> int:
    targets = argv[1:] or list(CLIENTS)
    unknown = [t for t in targets if t not in CLIENTS]
    if unknown:
        die(f"unknown client(s): {', '.join(unknown)}; valid: {', '.join(CLIENTS)}")
    servers = load_source()
    for t in targets:
        try:
            CLIENTS[t](servers)
        except FileNotFoundError as e:
            print(f"gen-mcp: skip {t}: {e}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
