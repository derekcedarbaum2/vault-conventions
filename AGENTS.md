# AGENTS.md — `vault-conventions`

Operating protocol for agents installing the vault-side patterns from this repo.

## What this repo provides

Vault structure, frontmatter discipline, and hygiene tooling for Markdown knowledge bases that AI agents read from and write to. CLAUDE.md template, YAML frontmatter schema, `/prune-memory` skill, `SessionEnd` archive hook, concurrency lockdir pattern.

## Read order

1. `README.md` — the vault model, the conventions, why each one exists.
2. `templates/CLAUDE.md` — the vault-level CLAUDE.md template (folder map, conventions, knowledge router pointer).
3. `templates/_learnings.template.md` — per-folder domain file template.
4. `skills/prune-memory/SKILL.md` — periodic memory pruning skill.
5. `hooks/archive-session.sh` — `SessionEnd` hook that auto-saves transcripts.

## Trust boundary

- The conventions are opinionated. Each one is documented with reasoning in `README.md` — read the *why* before adapting.
- The frontmatter schema is non-negotiable for the conventions to work. Optional fields can be added; required ones cannot be removed.
- The `archive-session.sh` hook writes raw transcripts to a vault path. If the operator's vault is in a sync'd location (iCloud, Dropbox), be aware of the write window.

## Install

For a Claude Code operator with an Obsidian (or any markdown) vault:

```bash
# 1. CLAUDE.md (vault-level) — adapt folder map to operator's vault structure
cp templates/CLAUDE.md <operator-vault>/CLAUDE.md

# 2. Frontmatter schema applies retroactively — backfill on edit
# (no install step; the schema is documented in CLAUDE.md)

# 3. SessionEnd hook
cp hooks/archive-session.sh ~/.claude/hooks/
chmod +x ~/.claude/hooks/archive-session.sh
# Then add SessionEnd hook config to ~/.claude/settings.json

# 4. /prune-memory skill
cp -r skills/prune-memory ~/.claude/skills/
```

## Adaptation checklist

- [ ] Operator's vault root path identified.
- [ ] `templates/CLAUDE.md` folder map matches operator's actual folder structure (or operator agrees to migrate to it).
- [ ] Operator's existing markdown files have frontmatter (or `vault-lint` is installed to find ones missing it — see [`vault-lint`](https://github.com/derekcedarbaum2/vault-lint)).
- [ ] Session archive path in `archive-session.sh` matches operator's vault.
- [ ] If operator uses iCloud / Dropbox sync, lockdir pattern applies for any concurrent writes.

## Conventions covered

| Convention | What it solves |
|---|---|
| Vault folder map | Every artifact has one obvious home. No "where does this go?" |
| YAML frontmatter on every `.md` | Enables Dataview queries, status filtering, type-based routing. |
| `_learnings.md` per venture/engagement folder | Append-only running context per domain. |
| Knowledge Router (in MEMORY.md) | Maps task patterns → which `_learnings.md` to load. |
| `SessionEnd` archive hook | Never lose a session. Raw transcripts auto-saved. |
| Concurrency lockdir for cron-driven writes | Prevents self-overlap when prior cron run hasn't finished. |
| Operation log (`log.md`) | Append-only audit trail of vault-modifying ops. |

## Related repos

- [`ai-knowledge-system`](https://github.com/derekcedarbaum2/ai-knowledge-system) — the memory pattern these conventions support.
- [`vault-lint`](https://github.com/derekcedarbaum2/vault-lint) — automated audit that flags frontmatter, broken wiki-links, contradictions, etc.
- [`agentic-architecture-map`](https://github.com/derekcedarbaum2/agentic-architecture-map) — internal architecture-tracking pattern that pairs with these conventions.
