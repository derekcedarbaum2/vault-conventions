# Vault Conventions for AI Agents

**Vault structure, frontmatter discipline, and hygiene tooling for markdown knowledge bases that AI agents read from and write to.**

The vault is where your agent's long-term knowledge lives. Without conventions, it rots — orphans, broken links, conflicting `_learnings.md` files, a `MEMORY.md` that crept past 200 lines. With conventions, it compounds. This repo is the hygiene layer.

Pairs with:
- [`ai-knowledge-system`](https://github.com/derekcedarbaum2/ai-knowledge-system) — the three-tier persistent-memory pattern this hygiene supports
- [`vault-lint`](https://github.com/derekcedarbaum2/vault-lint) — read-only audit (orphan pages, broken wikilinks, stale `_learnings.md`, contradictions)
- [`note-highlight-indexer`](https://github.com/derekcedarbaum2/note-highlight-indexer) — daily Readwise → playbook ingestion that fills the vault

---

## What's in this repo

```
vault-conventions/
├── README.md                              ← this file
├── templates/
│   ├── CLAUDE.md.template                 ← starter vault rules file
│   └── frontmatter-schema.md              ← the YAML frontmatter spec
├── skills/
│   └── prune-memory/SKILL.md              ← MEMORY.md hygiene skill
└── hooks/
    ├── archive-session.sh                 ← SessionEnd hook (raw transcript safety net)
    └── concurrency-lockdir-snippet.sh     ← shared-file pipeline lock pattern
```

Six files, all opinionated, all useful in isolation.

---

## What each piece does

### 1. `templates/CLAUDE.md.template`

A starter `CLAUDE.md` for the **root of your vault** — not your global agent rules at `~/.claude/CLAUDE.md`, but the per-vault file that tells your agent how *this* vault is organized. Folder taxonomy, the "single rule" for filing, autonomy guidelines, link conventions.

Copy into your vault root, replace placeholders, edit to match your structure.

### 2. `templates/frontmatter-schema.md`

The opinionated YAML frontmatter spec every `.md` file in the vault should follow. Required fields (`title`, `type`, `status`, `classification`, `created`, `updated`, `author`, `tags`) plus optional ones for product/program/source/owner/due.

Why a schema? It drives Dataview queries, lint rules, and agent behavior. Without a schema, your vault is a bag of markdown — with one, it's a queryable database.

### 3. `skills/prune-memory/`

A Claude Code skill that audits your `MEMORY.md` for:

- **Growth** (200-line hard cap on Claude Code; lines past 200 get truncated)
- **Duplication with CLAUDE.md** (tier-1 already loads on every call — tier-2 should never repeat it)
- **Stale memories** (project archived, deadline passed, MCP changed)
- **Consolidation candidates** (two memories covering the same topic)
- **Tier-2 → tier-1 promotion candidates**

Read-only by default. Asks before deleting anything.

### 4. `hooks/archive-session.sh`

A `SessionEnd` hook for Claude Code. Captures the raw transcript of every session at close into your vault as a markdown file with proper frontmatter. **The safety net** — even when you forget to run `/archive-session`, you don't lose the conversation.

The shell script is the cheap, deterministic layer. A skill (like the `archive-session` skill in [`ai-knowledge-system`](https://github.com/derekcedarbaum2/ai-knowledge-system/tree/main/skills/archive-session)) can later enrich the raw archive with extracted decisions, insights, open threads. Two layers: hook for safety, skill for value.

Wire it into `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionEnd": [
      {"command": "/path/to/archive-session.sh"}
    ]
  }
}
```

### 5. `hooks/concurrency-lockdir-snippet.sh`

A pattern, not a hook. Drop into any cron'd shell script that writes to shared vault files (Readwise distill, voice-memo processor, vault auto-archiver) to prevent two runs from racing each other.

Atomic `mkdir` lock + `trap` cleanup + stale-lock recovery + interactive-session bypass. Earned-once-the-hard-way pattern.

---

## Install

Pick the pieces you want — they're independent.

### Vault rules + frontmatter schema (5 minutes)

```bash
# Drop the vault rules template into your vault root
cp templates/CLAUDE.md.template /path/to/your/vault/CLAUDE.md
# Then edit to match your folder structure

# Reference the frontmatter schema (or copy it inline into CLAUDE.md)
cp templates/frontmatter-schema.md /path/to/your/vault/frontmatter-schema.md
```

### `/prune-memory` skill — Claude Code

```bash
mkdir -p ~/.claude/skills/prune-memory
cp skills/prune-memory/SKILL.md ~/.claude/skills/prune-memory/SKILL.md
```

Invoke with `/prune-memory`.

### `/prune-memory` skill — Codex CLI

Codex doesn't have a skill loader. Use the `SKILL.md` as a prompt template:

```bash
mkdir -p ~/.codex/prompts
cp skills/prune-memory/SKILL.md ~/.codex/prompts/prune-memory.md
```

Paste the file into a Codex session, or wrap in a shell alias.

### SessionEnd hook (Claude Code only)

```bash
# Pick your vault location and edit the hook
cp hooks/archive-session.sh ~/.claude/hooks/archive-session.sh
chmod +x ~/.claude/hooks/archive-session.sh
# Open ~/.claude/hooks/archive-session.sh and set VAULT_DIR
```

Then add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "SessionEnd": [{"command": "$HOME/.claude/hooks/archive-session.sh"}]
  }
}
```

### Concurrency lockdir snippet

It's a snippet, not a binary. Crack open any cron'd shell script, copy the relevant block, set `LOCK_NAME` to something unique per pipeline, drop your work below the `# your pipeline below` line.

---

## Usage rhythm

| When | What | Tool |
|---|---|---|
| Every session close | Raw transcript saved | `archive-session.sh` (automatic) |
| Weekly | Vault health check | [`/vault-lint`](https://github.com/derekcedarbaum2/vault-lint) |
| Bi-weekly | Memory hygiene | `/prune-memory` |
| When you build a daily cron | Add lock pattern | `concurrency-lockdir-snippet.sh` |
| When you onboard a new venture/engagement | Copy `_learnings.md` skeleton | (in [`ai-knowledge-system`](https://github.com/derekcedarbaum2/ai-knowledge-system)) |

---

## License

MIT. The conventions are more valuable than the code — fork, adapt, and don't be precious about the schema. Whatever discipline survives 6 months of real use is the right discipline.
