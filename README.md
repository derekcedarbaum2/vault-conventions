# Vault Conventions for AI Agents

> **Want to install the whole 12-repo ecosystem?** Paste [this prompt](https://github.com/derekcedarbaum2/claude-code-setup/blob/main/INSTALL-PROMPT.md) into your Claude Code or Codex session — it interviews you, installs in phases, runs smoke tests, and pauses for confirmation between phases. Or browse the [ECOSYSTEM map](https://github.com/derekcedarbaum2/claude-code-setup/blob/main/ECOSYSTEM.md) first.


**Rules and tools that keep an AI agent's Markdown knowledge base from rotting over time.**

> **New to Claude Code?** [Claude Code](https://docs.anthropic.com/claude/code) is Anthropic's command-line AI agent. A "vault" is a folder of Markdown files that the agent reads and writes — typically [Obsidian](https://obsidian.md). See the [ECOSYSTEM map](https://github.com/derekcedarbaum2/claude-code-setup/blob/main/ECOSYSTEM.md) for the full system overview + onboarding sequence. Vocabulary used here (vault, frontmatter, `_learnings.md`, hook, etc.) is defined in the [glossary](https://github.com/derekcedarbaum2/claude-code-setup/blob/main/GLOSSARY.md).

---

## The problem

Once you let an AI agent read and write into a Markdown knowledge base, you've got a new problem: the agent doesn't know what good filing looks like.

It'll create a meeting note in the wrong folder. Skip frontmatter. Make a new `_learnings.md` when one already exists. Save a transcript with no metadata. Append duplicate entries. Drop wikilinks that don't resolve. After a few months the vault is full of structural rot you didn't notice happening.

The fix isn't training the agent to be smart about filing every time. It's encoding the conventions in one place — a `CLAUDE.md` at the vault root that lays down the structure rules, a YAML frontmatter schema every file follows, a hook that auto-archives session transcripts in the right format, and a periodic audit that catches drift before it compounds.

This repo is that conventions layer. It pairs with the memory pattern in [`ai-knowledge-system`](https://github.com/derekcedarbaum2/ai-knowledge-system), the audit tool [`vault-lint`](https://github.com/derekcedarbaum2/vault-lint), and the daily Readwise ingestion in [`note-highlight-indexer`](https://github.com/derekcedarbaum2/note-highlight-indexer). On their own each is useful; together they keep the vault healthy at scale.

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
