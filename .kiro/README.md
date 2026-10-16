# Global Kiro config

This directory holds the portable, public parts of the global Kiro CLI setup.
`bootstrap.sh` (the `kiro` step) installs them into `~/.kiro/`.

## Contents

- `steering/` — global steering rules. Copied into `~/.kiro/steering/`.
  - `engineering-style.md` — language-agnostic engineering rules.
  - `interaction-voice.md` — reply voice and register (caveman and friends).
  - `obsidian-vault.md` — Obsidian note conventions.
- `hooks/` — global hooks. Copied into `~/.kiro/hooks/`.
  - `caveman-session-start.json` — turns on caveman voice at session start.
  - `kiro-changed.json` — queues changed files and opens them at end of turn.
- `skills-lock.json` — the record of which skills are installed, and from
  which upstream repo. See "Skills" below.
- `settings.json` — Kiro IDE settings (fonts, theme, trust defaults).

## Why copy, not symlink

The Kiro CLI reads hooks live and does not follow a symlink in
`~/.kiro/hooks/`. A linked hook is ignored. So `bootstrap.sh` copies steering
and hooks on every run. Repo edits propagate on the next run.

## Public and private steering

Steering splits into two sets:

- Public: the `steering/*.md` files here. They carry no employer, host, or
  project identifiers. Safe for a public repo.
- Private: work-specific steering (for example safety-standard rules, or notes
  that name internal systems). This never enters this public repo.

Both sets land in `~/.kiro/steering/` at install time, so Kiro loads them
together. The split lives only in the source, not at runtime.

To add the private set, point an environment variable at a directory of
private `*.md` steering files before you run the `kiro` step:

```sh
export KIRO_PRIVATE_STEERING="$HOME/path/to/private/steering"
./bootstrap.sh kiro
```

The bootstrap copies the private files last, so a private file wins over a
public file with the same name. The private directory is normally a clone of a
separate private git repo. That repo is wired separately and is not required
for the public setup to work.

## Skills

Skills are managed with the `skills` CLI (`npx skills`, from
`vercel-labs/skills`), not committed as files. `skills-lock.json` records the
installed set and its sources:

- `JuliusBrussee/caveman` — the caveman voice ecosystem (caveman, megacave,
  ultracave, and the rest the repo installs by default).
- `danyuchn/asd-ste100-skill` — the asd-ste100 technical-writing skill.
- `AminBlg/SimpleEnglish` — the simple-english plain-language skill.

The `kiro` bootstrap step restores them. It runs one `add` per repo:

```sh
npx -y skills@1.7.2 add JuliusBrussee/caveman   -a kiro-cli -g -y
npx -y skills@1.7.2 add danyuchn/asd-ste100-skill -a kiro-cli -g -y
npx -y skills@1.7.2 add AminBlg/SimpleEnglish   -a kiro-cli -g -y
```

Notes:

- The CLI needs Node 22.20.0 or later. `mise` provides Node, so run the `mise`
  step before the `kiro` step.
- Restore uses `add`, not `experimental_install`. `experimental_install` is
  experimental and did not complete non-interactively in testing.
- `-g` installs to the user scope (`~/.kiro/skills/`). `-a kiro-cli` pins the
  agent so the install path is deterministic.
- Review skills before use. They run with full agent permissions.
