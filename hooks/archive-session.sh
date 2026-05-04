#!/bin/bash
# SessionEnd hook: Archives raw Claude Code transcripts to Obsidian vault.
# Reads transcript_path, session_id, and cwd from stdin JSON.
# Skips if a rich archive (from /archive-session skill) already exists.

set -euo pipefail

# EDIT THIS to your vault's session-archive directory, or set VAULT_DIR in your environment.
# Examples:
#   Obsidian (iCloud):  $HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/Vault/CC Chat History
#   OneDrive:           $HOME/Library/CloudStorage/OneDrive-Personal/Vault/CC Chat History
#   Plain folder:       $HOME/vault/CC Chat History
VAULT_DIR="${VAULT_DIR:-$HOME/vault/CC Chat History}"

# Read stdin JSON
INPUT=$(cat)
TRANSCRIPT_PATH=$(echo "$INPUT" | /usr/bin/jq -r '.transcript_path // empty')
SESSION_ID=$(echo "$INPUT" | /usr/bin/jq -r '.session_id // empty')
CWD=$(echo "$INPUT" | /usr/bin/jq -r '.cwd // empty')

# Bail if no transcript
if [ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ]; then
    exit 0
fi

# Bail if no session ID
if [ -z "$SESSION_ID" ]; then
    exit 0
fi

DATE=$(date +%Y-%m-%d)
SHORT_ID="${SESSION_ID:0:8}"
OUTPUT_FILE="${VAULT_DIR}/${DATE}-${SHORT_ID}.md"

# Derive a readable title from the first user message (first ~60 chars), fall back to project+date
FIRST_USER_MSG=$(/usr/bin/jq -r '
    select(.type == "user" and .message.role == "user")
    | if (.message.content | type) == "string" then .message.content
      elif (.message.content | type) == "array" then
          (.message.content | map(select(.type == "text")) | map(.text) | join(""))
      else empty end
' "$TRANSCRIPT_PATH" 2>/dev/null | head -1 | tr -d '\n' | tr -s ' ' | cut -c1-60 | sed 's/[[:space:]]*$//' | sed 's/"/\\"/g')

# Skip if rich archive already exists (written by /archive-session skill)
if [ -f "$OUTPUT_FILE" ]; then
    # Check if existing file has confidence field (indicates skill-generated rich archive)
    if grep -q "^confidence:" "$OUTPUT_FILE" 2>/dev/null; then
        exit 0
    fi
fi

# Derive project name from cwd
PROJECT=$(basename "$CWD")

# Compose title — prefer first user message, fall back to project name + date
if [ -n "$FIRST_USER_MSG" ]; then
    TITLE="${FIRST_USER_MSG}"
else
    TITLE="Session: ${PROJECT} — ${DATE}"
fi

# Count user turns
TURNS=$(/usr/bin/jq -r 'select(.type == "user" and .message.role == "user") | .type' "$TRANSCRIPT_PATH" 2>/dev/null | wc -l | tr -d ' ')

# Skip very short sessions (< 3 user turns — likely abandoned or accidental)
if [ "$TURNS" -lt 3 ]; then
    exit 0
fi

# Extract condensed transcript: user messages and assistant text, one-line tool summaries
TRANSCRIPT=$(/usr/bin/jq -r '
    if .type == "user" and .message.role == "user" then
        # User text messages
        if (.message.content | type) == "string" then
            "**User:** " + .message.content
        elif (.message.content | type) == "array" then
            # Skip tool results, only get text
            (.message.content | map(select(.type == "text")) | map(.text) | join("")) as $text |
            if ($text | length) > 0 then "**User:** " + $text else empty end
        else empty end
    elif .type == "assistant" and .message.role == "assistant" then
        if (.message.content | type) == "array" then
            # Get text blocks
            (.message.content | map(select(.type == "text")) | map(.text) | join("")) as $text |
            # Get tool use summaries
            (.message.content | map(select(.type == "tool_use")) | map("> [" + .name + "]") | join("\n")) as $tools |
            if ($text | length) > 0 and ($tools | length) > 0 then
                "**Assistant:** " + $text + "\n" + $tools
            elif ($text | length) > 0 then
                "**Assistant:** " + $text
            elif ($tools | length) > 0 then
                $tools
            else empty end
        elif (.message.content | type) == "string" then
            "**Assistant:** " + .message.content
        else empty end
    else empty end
' "$TRANSCRIPT_PATH" 2>/dev/null | head -300)

# Ensure output directory exists
mkdir -p "$VAULT_DIR"

# Write raw archive
cat > "$OUTPUT_FILE" << ENDOFFILE
---
title: "${TITLE}"
type: session
status: archived
classification: internal
created: ${DATE}
updated: ${DATE}
author: "${ARCHIVE_AUTHOR:-$(whoami)}"
tags: [raw-archive]
date: ${DATE}
session_id: ${SESSION_ID}
session_type: unknown
project: ${PROJECT}
summary: "Raw archive — run /archive-session to enrich with AI-extracted metadata."
confidence: raw
decisions: []
artifacts_created: []
artifacts_modified: []
open_threads: []
insights: []
follow_up: []
stack: []
turns: ${TURNS}
---

# Session: ${DATE} — Raw Archive

## Summary

Raw transcript archive. Run \`/archive-session ${OUTPUT_FILE}\` to generate a rich archive with decisions, insights, and metadata.

## Condensed Transcript

${TRANSCRIPT}
ENDOFFILE
