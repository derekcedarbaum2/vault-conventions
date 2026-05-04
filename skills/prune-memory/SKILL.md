---
name: prune-memory
description: Audit MEMORY.md for stale, duplicate, or CLAUDE.md-overlapping entries. Enforces the 200-line cap. Suggests trims, consolidations, and tier promotions. Use when the user says "prune memory", "trim memory", "audit memory", or invokes `/prune-memory`.
version: 1.0.0
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Prune Memory

Keeps MEMORY.md tight, accurate, and within the 200-line hard cap. Auto-memory system grows as you work — this skill prevents drift and bloat.

**Memory files live at:** `~/.claude/projects/-<your-username>/memory/`
**Index:** `MEMORY.md` — should always stay under 200 lines

## When to use

Activate when user says:
- "prune memory" / "audit memory" / "trim memory"
- "is MEMORY.md getting too big?"
- "check for stale memories"
- Invokes `/prune-memory`

Also activate proactively:
- After a `/distill` run (distill includes a memory maintenance pass — this skill is the focused version)
- When MEMORY.md hits 150+ lines (approaching the cap)

Do NOT activate for:
- Adding a new memory (just write it directly)
- Looking up a memory (just Read the relevant file)

## Checks

### 1. Growth check

- Count lines in MEMORY.md
- Hard cap: 200 lines. Lines after 200 get truncated from context.
- Report current count, distance to cap, trend (if you've run this before — log in `log.md`)
- Severity: **Critical** if > 180 lines, **Warning** if > 150, **Info** if < 150

### 2. Duplicate-with-CLAUDE.md

- Read `~/.claude/CLAUDE.md`
- For each memory file, check whether its content is already expressed in CLAUDE.md
- If yes → that memory is redundant (CLAUDE.md loads on every call anyway)
- Suggest deletion with rationale
- Severity: **Warning**

### 3. Stale memories

- A memory is potentially stale if:
  - It references a project / initiative / person no longer active
  - It references a date / deadline that has passed without update
  - The Knowledge Router points to an `_learnings.md` that doesn't exist
  - The MCP / tool / API it documents has changed
- This check requires judgment — read each memory file and assess
- Severity: **Warning** (user should confirm before removal)

### 4. Overlapping memories (consolidation candidates)

- Two memory files that cover the same topic should merge
- Detection: similar `name:` or `description:` fields; overlapping content
- Suggest a consolidation target and a trim script
- Severity: **Info**

### 5. Tier-1 promotion candidates

- A `_learnings.md` entry that has become **operational** (a rule that prevents failure across many sessions) should be promoted to MEMORY.md
- Ask the user to flag candidates during distill runs or regular work — the skill can't identify these automatically, but it can highlight frequently-cited `_learnings.md` entries and ask

### 6. Type audits

- Every memory file has `type: user | feedback | project | reference`
- Audit that the content matches the type:
  - `user` = who Derek is, how he works
  - `feedback` = how to work with Derek (rules, preferences)
  - `project` = active initiatives, context
  - `reference` = pointers to external resources
- Mismatches = **Info**

## Workflow

1. **Scan the memory directory** — Glob `~/.claude/projects/-<your-username>/memory/*.md`
2. **Read MEMORY.md** — get current line count and all index entries
3. **Read each memory file** — collect name, description, type, content
4. **Read CLAUDE.md** — for duplication check
5. **Run checks 1–6** — mostly mechanical; stale check (#3) needs judgment
6. **Compile report** — findings grouped by severity
7. **Present to user** — ask which fixes to apply before touching anything
8. **Apply approved fixes** — delete / edit files, update MEMORY.md index

## Output

```markdown
# Memory Audit — {{DATE}}

## Summary

- Memory files: {{N}}
- MEMORY.md lines: {{N}} / 200 ({{percent}}% of cap)
- Issues: {{Critical N}} / {{Warning N}} / {{Info N}}

## Growth

MEMORY.md: {{current}} lines. Cap 200. Headroom: {{remaining}}.

{{If trend data in log.md:}} Trend over last 3 runs: {{delta}}.

## Candidates for removal

### Duplicates with CLAUDE.md ({{N}})

| Memory file | Overlaps with | Recommendation |
|---|---|---|
| ... | CLAUDE.md §{{section}} | Delete — fully redundant |

### Potentially stale ({{N}})

| Memory file | Reason | Recommendation |
|---|---|---|
| ... | Project dormant since YYYY-MM-DD | Confirm with user — delete or update |

## Candidates for consolidation ({{N}})

### Group A

- `memory-file-1.md` — covers X
- `memory-file-2.md` — also covers X

**Suggested merge:** {{target file name}}. Combine content, update index.

## Candidates for promotion ({{N}})

Rules currently in `_learnings.md` that may warrant Tier 1 promotion:

| `_learnings` location | Rule | Why promote |
|---|---|---|

## Type audit ({{N}})

| File | Declared type | Actual content | Suggestion |
|---|---|---|---|

## Recommended actions

1. Delete: {{N}} files
2. Consolidate: {{N}} pairs
3. Review stale: {{N}} files (user decision)
4. Promote: {{N}} candidates (user decision)

Proceed with deletions? (y/n)
Proceed with consolidations? (y/n)
```

## Rules

- **Never delete a memory file without user confirmation.** Even obvious duplicates need a y/n.
- **Promotion to MEMORY.md is always user-initiated.** The skill surfaces candidates; the user decides.
- **Log every memory action in vault `log.md`** — what was deleted, consolidated, promoted, when.
- **Preserve the `projects/-<your-username>/memory/` directory structure.** Don't move files to other paths.
- **Index integrity** — after any deletion or consolidation, update `MEMORY.md` so no dangling index entries remain.

## Quick-win patterns

When reviewing findings, these are almost always safe to apply:

1. Delete a memory whose content is verbatim in CLAUDE.md.
2. Consolidate two memories with near-identical `name:` fields.
3. Delete a `project` type memory when the project is confirmed archived.

Never safe without review:
1. Deleting any `feedback` type memory (corrections are load-bearing).
2. Renaming or moving memory files (breaks the index).
3. Bulk type changes (each entry needs its own judgment).

## Related

- `/vault-lint` — sibling skill for vault-side health
- `/distill` — includes a memory maintenance pass as part of its run
- `reference_knowledge_router.md` — the most important memory; don't prune it

## Antipatterns to avoid

- **Auto-deleting "obvious" duplicates without confirmation.** Even verbatim CLAUDE.md duplicates can be there for a reason (separation of concerns, role-isolated context). Always ask.
- **Promoting to MEMORY.md without operational evidence.** A learning that *might* be operational isn't. Wait until it's been cited by 2+ sessions or until the user explicitly flags it.
- **Treating staleness as a signal to delete.** A memory referencing a dormant project isn't stale — it's archival. Move to a `_archive/` subdirectory; don't delete.
- **Silently breaking the MEMORY.md index.** Every deletion or consolidation must update the index entry too. Dangling index lines confuse the loader.
