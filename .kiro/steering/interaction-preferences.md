---
inclusion: always
---

# Interaction Preferences

Living document. It records how I want the agent to work with me and my
systems. Add to it and change it over time.

Voice and register live in `interaction-voice.md`. Code structure, comments,
verification, and supply-chain live in `engineering-style.md`. This file holds
the rest: install, CLI use, git, and working defaults.

## Install preferences

Install each tool from the first source that can provide it, in this order:

1. mise. This is the single source of truth for command-line tools.
2. cargo. Use it for tools that mise does not provide (for example neovide,
   tinty, stylua, tree-sitter).
3. apt (Debian, Ubuntu, WSL). Use it only for things mise and cargo cannot
   give: the system toolchain and the `-dev` headers, and runtime binaries
   that are not already on the PATH.
4. winget (native Windows). Use it for GUI applications and fonts (for example
   WezTerm, Neovide, Kiro IDE, Nerd Fonts). Prefer winget over a manual
   download, because winget is scriptable and repeatable.
5. A pinned installer. Use a pinned or checksummed installer before a blind
   `curl ... | sh`. Keep `curl | sh` as a documented fallback only.

Rules for every install step:

- Make the step idempotent. Do not install again what is already present.
- Make the step host-aware (Linux, WSL, Windows).
- Do not install from apt what a portable manager can provide.

## CLI tool usage

- Inspect a command-line tool before you use it. Do not guess flags and
  arguments.
- Read the tool's help first. Use `<tool> --help`, `<tool> help`, or
  `<tool> <subcommand> --help`. Prefer the tool's own help over memory.
- Get the tool version. Use `<tool> --version`. The flags depend on the
  version, so record the version you saw.
- Prefer the help text and the version over an assumption. State which you
  checked.
- Use the man page or the official docs only when the built-in help is
  missing or unclear.
- Inspect each tool once per task. Do not re-check a tool you already
  inspected this session.

## Git and commits

- Check in before every push. The flow is: I draft the message, you approve it,
  I ask "amend or new commit", you confirm, then I push.
- Write commit messages in ASD-STE100. Use short bulleted sentences.
- The iteration alias is `iter` (`au` then `cane` then `fwl`): stage the tracked
  changes, amend with no edit, and force-push with lease.
- Stage files by name. Do not use `git add .` or `git add -A`.
- Do not include unrelated changes in a commit. Flag them instead.
- Use the anonymized Git identity.

## Interaction defaults

- Never assume the date or carry one from earlier context. Whenever a prompt
  touches time at all - "now", "today", "tomorrow", "yesterday", "this week",
  a day name, a deadline, scheduling, "latest", "current", relative ages, or
  any date arithmetic - first inspect the real date with the `date` utility
  (for example `date "+%Y-%m-%d %A %Z"`) or an equivalent means, and reason
  from that. Re-inspect for each such prompt; do not reuse an earlier reading
  if the session may have crossed a day boundary.
- Be honest about what is verified against what is assumed.
- Read a file before you change it.
- Prefer package managers over manual steps.
- Prefer small, reviewable changes.
