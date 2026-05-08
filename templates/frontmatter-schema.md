# YAML Frontmatter Schema

Every `.md` file in your vault should open with a frontmatter block. The schema below is **opinionated** — start here, customize after you've used it for a few weeks.

## The base schema

```yaml
---
title: <document title — short, scannable>
type: <prd | reference | meeting | cta | research | concept | session | essay | idea | ephemeral>
status: <draft | active | approved | archived>
classification: <public | internal | confidential | unclassified>
created: YYYY-MM-DD
updated: YYYY-MM-DD
author: "<your name>"
tags: []
---
```

## Field-by-field

### `title` (required)
The document's short title. Should match the H1 if there is one. Don't repeat the filename.

### `type` (required, enum)
What *kind* of document this is. Drives lint rules, agent behavior, and Dataview queries.

| Value | Meaning |
|---|---|
| `prd` | Product Requirements Document |
| `reference` | Static reference content (specs, schemas, glossaries, brand guides) |
| `meeting` | Meeting notes (1:1s, syncs, externals) |
| `cta` | A document containing action items / commitments |
| `research` | Market research, user interviews, competitive analysis |
| `concept` | A standalone concept node — synthesized from many sources |
| `session` | An AI agent session archive (auto-written by hooks/skills) |
| `essay` | Long-form personal writing |
| `idea` | Early-stage product or business idea, pre-PRD |
| `ephemeral` | Regenerated derived view (not memory). Examples: `Today.md` (working state aggregator), generated indexes/dashboards. Whole-file overwritten on each regen. Other tools (lint, archive, backup) should treat ephemeral files as transient. |

Add new types only when 3+ documents need them. Otherwise use the closest existing one.

### Ephemeral files — additional conventions

When `type: ephemeral`, also include:

```yaml
regenerated_by: <skill or script name>     # who regenerates this
updated: YYYY-MM-DDTHH:MM                  # timestamp, not just date — staleness matters
```

Hard rules:
- Ephemeral files are **whole-file overwritten** on each regen. No append-only invariant.
- Never edit by hand. Anything you'd want to persist belongs in a non-ephemeral file.
- Lint and archive tooling should **skip** ephemeral files for orphan / stale-link checks (the file's purpose is to be regenerated).
- Do not commit ephemeral files to a public repo. They contain current operational state.

### `status` (required, enum)
Lifecycle state.

| Value | Meaning |
|---|---|
| `draft` | Work in progress; don't share externally |
| `active` | Current, in-use, accurate as of `updated` |
| `approved` | Frozen and signed off (PRDs, specs that have shipped) |
| `archived` | No longer current; kept for history |

### `classification` (required, enum)
Sensitivity tier. Drives access decisions and agent behavior.

| Value | Meaning |
|---|---|
| `public` | OK to publish externally |
| `internal` | Share within team / company |
| `confidential` | Restricted — named recipients only |
| `unclassified` | Not yet evaluated (treat as `internal` until a human classifies) |

Agents should refuse to move `confidential` content into `public` folders without explicit user confirmation.

### `created` / `updated` (required, ISO date)
Always `YYYY-MM-DD`. Update `updated` whenever you edit.

### `author` (required, string)
Who created the document. Single name, quoted. For AI-generated content, still attribute to the human directing the work.

### `tags` (optional, array)
Free-form labels. Keep them lowercase, hyphenated, and short. Use sparingly — over-tagging is worse than under-tagging.

## Optional fields (use when relevant)

```yaml
product: <product name>          # for PRDs and product-specific docs
program: <program / contract>     # for engagement-tracked work
related: [[Note Title 1]], [[Note Title 2]]   # explicit cross-references
source: <URL or citation>         # for imported content
owner: <name>                     # who's responsible for this work
due: YYYY-MM-DD                   # for CTA-type docs
last_reviewed: YYYY-MM-DD         # for `_learnings.md` files
```

## Why this schema

- **`type` and `status`** drive Dataview queries. Want every active PRD? `WHERE type = "prd" AND status = "active"`.
- **`classification`** is a guardrail. Lint and agents read it before publishing or moving content.
- **`created` / `updated`** drive staleness checks. The `vault-lint` skill flags `_learnings.md` files where `updated` is > 60 days old.
- **`tags`** are for serendipitous discovery, not formal taxonomy. The taxonomy lives in `type`.

## Backfill strategy

If you're adopting this schema on an existing vault:

1. Don't try to backfill in one pass — it'll feel like busywork.
2. Add frontmatter to a file when you next *edit* it.
3. Run `vault-lint` (or any frontmatter-check tool) once a quarter to surface remaining gaps.
4. After ~3 months of organic backfill, do one focused sprint to close the long tail.

## Customization

This schema is a starting point. Common customizations:

- **Add a `product` enum** instead of free-text, if you have a fixed product set.
- **Rename `program` → `client`** for consultants.
- **Add a `cycle` or `quarter` field** if you plan in fixed time boxes.
- **Drop `classification`** if all your content is one tier (e.g., personal-only vault).

Whatever you choose, **document it in your vault's `CLAUDE.md`** so the agent knows what's required and what's optional.
