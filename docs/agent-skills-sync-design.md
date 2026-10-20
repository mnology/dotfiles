# Agent skills and steering: shared sources for Kiro and Cline

## Goal

One repo copy of each skill and steering rule. Kiro and Cline read the same
files. No copies that drift.

## Layout

| Asset | Source | Kiro | Cline |
|---|---|---|---|
| Lock-tracked skills (caveman, asd-ste100, simple-english, and the rest of 24) | `~/.agents/skills/` (written by `skills` CLI) | `~/.kiro/skills/<name>` symlink | reads `~/.agents/skills/` |
| `obsidian-vault` skill | `agents/skills/obsidian-vault/` in this repo | `~/.kiro/skills/obsidian-vault` symlink | `~/.agents/skills/obsidian-vault` symlink |
| AWS skills | AWS toolkit | real folders in `~/.kiro/skills/` | not shared |
| `engineering-style.md`, `interaction-preferences.md`, `interaction-voice.md` | `.kiro/steering/` in this repo | copied to `~/.kiro/steering/` | symlink in `~/.cline/rules/` |
| `caveman-session-start` hook | `.kiro/hooks/` in this repo | copied to `~/.kiro/hooks/` | not applicable (Kiro-only) |
| Private steering (`KIRO_PRIVATE_STEERING`) | separate private repo | copied to `~/.kiro/steering/` | copied to `~/.cline/rules/` |

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

## Trade-offs

- `engineering-style.md` loads in every Cline session, about 10k tokens per
  turn. It is meant for coding, infra, and tool work. Cline has no per-rule
  scope to limit it.
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
