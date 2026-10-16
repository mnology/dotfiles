---
inclusion: fileMatch
fileMatchPattern: "**/*.md"
---

# Obsidian vault conventions

This repo is an Obsidian vault. Apply these rules when you create or edit a
markdown note here. The goal is a lean, non-redundant, linked vault.

Prose style: write note bodies in ASD-STE100 (the asd-ste100 skill). Short
sentences. Active voice. One idea per sentence. No semicolons. Keep hedges.

## Frontmatter

Every note starts with YAML frontmatter.

Required keys: `title`, `type`, `status`, `date`, `tags`.
Optional keys: `project`, `owner`, `backup`, `related`.

Template:

```yaml
---
title: "Short descriptive title"
type: <from registry>
status: <from registry>
date: YYYY-MM-DD
project: my-project
owner: your-username
tags: [<from registry>, ...]
related: ["[[Other Note]]"]
---
```

## Taxonomy: inspect, reuse, coin, record

The vocabulary is living, not fixed. The registry is `_taxonomy.md`.

Before you set `type`, `status`, or `tags` on a note:

1. Read `_taxonomy.md`.
2. Scan existing note frontmatter in the vault for values already in use.
   Grep is enough: `grep -rhE '^(type|status|tags):' --include='*.md'`.
3. Reuse an existing value when one fits the content. Do not add a
   near-synonym of a value that already exists.
4. Coin a new value only when the content fits no existing value. Keep it
   lower-case and hyphenated. One idea per value.
5. When you coin a value, add a row to `_taxonomy.md` with a one-line
   definition in the same edit.

Categorize by content, not by guess. Read what the note says, then pick the
`type` and `tags` that match it.

## Lean and linked: do not repeat a fact

One fact lives in one note. Other notes link to it. Do not restate it.

- Link to a section: `[[Note title#Section heading]]`.
- Embed a section inline: `![[Note title#Section heading]]`. Use this when a
  note must show a fact that another note owns.
- Pin a volatile fact with a block id, so a link survives a heading rename:
  put `^some-id` on the block, then link `[[Note#^some-id]]`.
- Make links bidirectional. Add a `related` entry, or a one-line back-link, in
  both notes.

Before you write a fact, check whether another note already owns it. If it
does, link or embed instead of copying.

## Bases compatibility

The vault index is `_index.base`. It queries frontmatter. So frontmatter must
be consistent for a note to appear. A note with no `type` does not appear in
the index. Set the required keys so new notes show up.

## File naming

- Use a clear, human title in the filename.
- A date-specific note carries the date: `Team Network Meeting 2026-10-14`.
- Registry and index notes start with `_` so they sort to the top.
