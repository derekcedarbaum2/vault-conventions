#!/bin/bash
# Concurrency lockdir pattern — prevents shared-file pipelines from overlapping.
#
# Use case: you run a daily cron (Readwise distill, voice-memo processor, vault
# auto-archiver) that writes to shared files. Two runs racing each other corrupt
# state. This pattern uses an atomic mkdir to ensure only one runs at a time.
#
# Properties:
# - Atomic: mkdir is the canonical "test and set" on POSIX
# - Auto-cleanup on exit (success, error, or signal) via trap
# - Stale-cleanup if a previous run died without releasing (configurable timeout)
# - Interactive sessions don't lock (they should not block themselves)
#
# Wire this into your cron'd shell scripts that write to shared files.

set -euo pipefail

# ---------- config ----------
LOCK_NAME="${LOCK_NAME:-my-pipeline}"     # change per pipeline
LOCK_DIR="/tmp/${LOCK_NAME}.lock.d"
STALE_AFTER_SECONDS=$((2 * 60 * 60))      # 2 hours

# ---------- skip lock for interactive sessions ----------
# Detect if we're running interactively (e.g., the user invoked the script
# directly from a Claude Code session). Locking inside an interactive
# session is the wrong behavior — the user is the rate limiter, not cron.
if [ -t 0 ] || [ -n "${FORCE_NO_LOCK:-}" ]; then
    SKIP_LOCK=1
else
    SKIP_LOCK=0
fi

# ---------- stale lock cleanup ----------
if [ "$SKIP_LOCK" -eq 0 ] && [ -d "$LOCK_DIR" ]; then
    LOCK_AGE_SECONDS=$(($(date +%s) - $(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR")))
    if [ "$LOCK_AGE_SECONDS" -gt "$STALE_AFTER_SECONDS" ]; then
        echo "Removing stale lock (${LOCK_AGE_SECONDS}s old, threshold ${STALE_AFTER_SECONDS}s)"
        rmdir "$LOCK_DIR" 2>/dev/null || true
    fi
fi

# ---------- acquire ----------
if [ "$SKIP_LOCK" -eq 0 ]; then
    if ! mkdir "$LOCK_DIR" 2>/dev/null; then
        echo "Another run is already in progress (lock at $LOCK_DIR). Exiting."
        exit 0
    fi
    # Release on any exit
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT INT TERM
fi

# ---------- your pipeline below ----------
# (replace with the actual work — Readwise distill, voice memo, vault archive,
# whatever. The lock guarantees no overlap with another instance of THIS script.)

echo "Pipeline starting: $LOCK_NAME"
# ... do work ...
echo "Pipeline complete: $LOCK_NAME"
