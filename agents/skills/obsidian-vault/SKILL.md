---
name: obsidian-vault
description: Use when creating or editing notes in an Obsidian vault. Covers frontmatter, taxonomy, linking, and file naming.
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

## Processing raw daily notes

"Process the notes" (or "process today's / yesterday's notes") means this
procedure. A raw daily note is a note whose name is an ISO 8601 date
(`YYYY-MM-DD.md`, for example `2026-10-21.md`). It holds meeting transcripts,
emails, and rough text captured during the day. Processing turns that raw
capture into classified, linked topic notes.

### Step 1: find the raw notes

A date-named note (name matches ISO 8601 `YYYY-MM-DD`) with no YAML frontmatter
is RAW (not processed). A date-named note that starts with `---` is processed;
leave it. Detect, without hardcoding the year:

```bash
for f in notes/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  [ -e "$f" ] || continue
  [ "$(head -1 "$f")" = "---" ] && echo "$f PROCESSED" || echo "$f RAW"
done
```

"Today" and "yesterday" are the real calendar dates, not the newest file. Read
the date before you pick a file.

### Step 2: classify by topic, not by form

An email, a document, or a transcript is a source, not a note type. Do not
create a note classified as an email or a document. Classify every item by its
subject, using a `type` from the taxonomy (`topic`, `investigation`,
`meeting-notes`, `position`). A long email thread about egress routing becomes
content in the egress-routing topic note.

### Step 3: find the threads and collect every party's view

A thread is one subject that runs across several emails or meetings. For each
subject, find the whole thread in the raw text, then collect every party's
stated view in the topic note, attributed by name, in one place. Keep a view
verbatim or close to it when the exact wording carries weight (a commitment, a
refusal, a date, a cost figure). Do not merge two parties into one voice. Do not
drop a dissenting view. Interlink the topic note with the daily note and with
every related topic, both directions.

### Step 4: break out or fold in

For each subject:

- If a note already owns it, FOLD the new facts into that note. Add them under
  the right heading, answer any open question they resolve, and add a `related`
  link. Do not create a near-duplicate.
- If no note owns it, CREATE one, classified by content. Interlink both ways.
- Check the taxonomy and existing frontmatter first. Reuse a type and tags
  before coining.

### Step 5: convert the date note to a processed standup

Once the subjects are broken out, rewrite the date note as a `type: standup`
note in the shape of the most recent processed standup: frontmatter, a short
"Bring to standup" section, a "Follow-ups" section, and `related` links to every
note broken out of it. The date note keeps the recap and the links. The detail
lives in the broken-out notes.

A task's canonical home is its topic or investigation note, never the standup. A
standup references a task by linking to the owning note; it does not own a
`- [ ]` line. Move any open `- [ ]` task in a standup to its owning topic note,
and leave a reference link in the standup. Leave done `- [x]` items in the
standup as dated history.

### Step 6: tasks and open questions are typed work items

Two kinds of work surface from notes. Keep them separate; do not merge into a
"follow-ups" catch-all.

- **Task:** an action the owner must take. Written as `- [ ]` (open) or `- [x]`
  (done). Lives in the subject note. Lifecycle: open to done.
- **Open question:** something that needs an answer before it is even
  actionable. Written as a bullet under a `## Open questions` heading. Lives in
  the subject note. Lifecycle: open, then it becomes a fact in the note body, or
  becomes a task, or is answered and removed.

Resolving an open question is a move, not a mark. When the answer is known, jot
it inline with the marker `(A: ...)`:

```
- Which link field carries SIMS to AEX? (A: the artifactory & mr field)
```

On the next processing pass, the `(A: ...)` marker is the signal to promote: if
the answer is a durable fact, move it into the note body and delete the
question; if it implies an action, make it a `- [ ]` task and delete the
question. A resolved question never stays in the Open questions section.

### Step 7: regenerate the roll-ups

Run the roll-up generator, which surfaces every task and every open question
into two generated windows:

```bash
python3 agent/tools/vault-rollup.py
```

It writes `notes/_todos.md` (every `- [ ]`, grouped by owning note) and
`notes/_open-questions.md` (every bullet under `## Open questions`, grouped by
owning note). Both files are generated. Never hand-edit them. Edit the task or
question in its owning note, then regenerate.

### Step 8: build a todo list on request

When asked for a todo list of what is outstanding in a date note, list every
open action as a checklist, grouped by subject, each item linked to the note
that owns the detail. `_todos.md` is the whole-vault version of this.

### Rules

- Do not invent a fact, a date, an owner, a Jira key, or an email line. Use only
  what the raw note holds. If a fact is unclear, keep it as written and flag it.
- Collect all parties' views in the topic note, attributed. Do not drop a view.
- One fact, one note: fold into the owner note; link, do not copy.
- When a link points at a source that holds the detail (a MR, a Jira issue, a
  Confluence page), link it and do not restate the detail. Keep only what the
  source does not own: the vault-specific framing, the task, the nuance. Do not
  duplicate fleet specs, steps, or figures that live in the linked source.
- A task lives in its subject note, never in a standup. The standup links to it.
- Resolve an open question by moving it out (to a fact or a task), not by
  leaving the answer beside it.
- Never wrap a `[[wikilink]]` across a line break. A wrapped link does not
  resolve. Keep each link on one line.
- Archive, do not delete, when you supersede a note.
