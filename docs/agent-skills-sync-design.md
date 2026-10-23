# Agent skills, steering, and MCP: shared sources for Kiro, Cline, and Goose

## Goal

One repo copy of each skill, steering rule, and MCP server definition. Kiro,
Cline, and Goose read the same sources. No copies that drift.

## Layout

| Asset | Source | Kiro | Cline | Goose |
|---|---|---|---|---|
| Lock-tracked skills (caveman, asd-ste100, simple-english, and the rest of 24) | `~/.agents/skills/` (written by `skills` CLI) | `~/.kiro/skills/<name>` symlink | reads `~/.agents/skills/` | reads `~/.agents/skills/` |
| `obsidian-vault` skill | `agents/skills/obsidian-vault/` in this repo | `~/.kiro/skills/obsidian-vault` symlink | `~/.agents/skills/obsidian-vault` symlink | via `~/.agents/skills/` |
| `engineering-style` skill | `agents/skills/engineering-style/` in this repo | `~/.kiro/skills/engineering-style` symlink | `~/.agents/skills/engineering-style` symlink | via `~/.agents/skills/` |
| AWS skills | AWS toolkit | real folders in `~/.kiro/skills/` | not shared | not shared |
| `engineering-style.md`, `interaction-preferences.md`, `interaction-voice.md` | `.kiro/steering/` in this repo | copied to `~/.kiro/steering/` | symlink in `~/.cline/rules/` | symlink in `~/.config/goose/`, auto-injected via `.goosehints` relative `@`-includes |
| MCP servers (aws-mcp, context7, sequential-thinking) | `agents/mcp/servers.json` in this repo | `mcpServers` in `~/.kiro/settings/mcp.json` (generated) | `mcpServers` in `~/.cline/data/settings/cline_mcp_settings.json` (generated) | `type: stdio` entries in `~/.config/goose/config.yaml` `extensions` (generated, builtins preserved) |
| `caveman-session-start` hook | `.kiro/hooks/` in this repo | copied to `~/.kiro/hooks/` | not applicable (Kiro-only) | not applicable |
| Private steering (`KIRO_PRIVATE_STEERING`) | separate private repo | copied to `~/.kiro/steering/` | copied to `~/.cline/rules/` | not yet wired |

## Why each mechanism

- **Skills use symlinks.** Unverified for Kiro: the design assumes Kiro loads
  skills through symlinks. Kiro does not follow symlinks for hooks, so hooks are
  copied (see `.kiro/README.md`).
- **Steering for Kiro is copied.** `bootstrap.sh kiro` copies on each run. Kiro
  already reads `~/.kiro/steering/`.
- **Steering for Cline is linked.** Edits in the repo apply at once. The
  `links` step creates the links.
- **Obsidian is a skill, not a rule.** Cline ignores `inclusion: manual`, and
  Cline rules have no scope. As a skill, the agent loads it by its
  description, or the user types `/obsidian-vault` in Kiro.
- **Goose steering uses relative `@`-includes.** `~/.config/goose/.goosehints`
  holds `@engineering-style.md` etc.; the three files are symlinked beside it in
  `~/.config/goose/`. Goose auto-injects relative `@`-includes at session start,
  deterministically, before the model runs — verified across sonnet, haiku, and
  qwen3-coder. Absolute `@`-paths do NOT auto-inject (they degrade to a plain
  "go read it" hint only strong models honour), so paths must be relative and
  the targets must live beside the hints file.
- **MCP is generated from one neutral source.** `agents/mcp/servers.json` is the
  single authority. `bin/gen-mcp.py` writes each client's native format: it
  replaces the custom MCP set and preserves everything else (Goose's `platform`
  builtins, its providers block, Kiro/Cline non-MCP keys). Add a server to the
  source, run bootstrap, and it propagates to every client. No secrets are
  written: aws-mcp carries only the AWS profile name and authenticates via SSO
  at runtime.

## Trade-offs

- `engineering-style` is a skill (loaded on demand), not an always-on rule. The
  always-on steering stub (`engineering-style.md`, ~1k tokens) points to it and
  keeps only the safety floor (supply chain, secrets, memory safety, AI-agent
  gates) inline. This removed the old ~10k-token-per-session cost of carrying
  the full ruleset always-on. Risk: the agent must trigger the skill by its
  description for the full detail to load; the safety floor is present either
  way. Cline has no per-rule scope, so Cline gets the stub always-on and loads
  the skill by description like the other skills.
- The Kiro `SessionStart` caveman hook does not run in Cline. The voice rule
  still says to default to caveman when the hook signal is absent.
- Kiro skill loading through a symlink is not yet verified (see Verification).

## Bootstrap

- `./bootstrap.sh links`: Cline rule links and the Obsidian skill links.
- `./bootstrap.sh kiro`: steering and hook copies, private overlay (both
  agents), and the skill restore for `kiro-cli` and `cline`.
- `DRY_RUN=1` prints each step without changes.

The skill restore runs one `skills@1.7.2 add` per source repo:
`JuliusBrussee/caveman`, `danyuchn/asd-ste100-skill`, `AminBlg/SimpleEnglish`.

## Verification

- Symlink counts: `~/.agents/skills` has 25 entries (24 lock-tracked + obsidian).
  `~/.kiro/skills` has 25 symlinks and 24 real AWS folders.
- `cline config --json` lists `engineering-style`, `interaction-preferences`,
  and `interaction-voice` as rules.
- Open: confirm in a new `kiro-cli chat` that `/simple-english`, `/caveman`,
  and `/obsidian-vault` load through the symlinks.
- Open: `npx skills@1.7.2 ls -g` output was not captured in a log.

## Rollback

- Remove the `~/.cline/rules/` links and the two obsidian skill links.
- Restore the backup tarball from before the migration.
- To go back to copies, run the skill restore with `-a kiro-cli` only.
