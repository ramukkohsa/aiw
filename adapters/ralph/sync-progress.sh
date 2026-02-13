#!/usr/bin/env bash
# adapters/ralph/sync-progress.sh — Syncs brief.md <-> Ralph TUI progress.md
# Usage: bash sync-progress.sh <project_name> [--pull|--push]
#   --pull: Copy from Ralph progress.md -> workspace brief.md
#   --push: Copy from workspace brief.md -> Ralph progress.md (default)

set -euo pipefail

WORKSPACE="${HOME}/.ai-workspace"

project="${1:?Usage: sync-progress.sh <project_name> [--pull|--push]}"
direction="${2:---push}"

config="${WORKSPACE}/config.toml"
proj_path=$(grep -A5 "\\[projects\\.${project}\\]" "$config" | grep "^path" | head -1 | sed 's/.*= *"//' | sed 's/".*//')

if [ -z "$proj_path" ] || [ ! -d "$proj_path" ]; then
    echo "Error: Project '${project}' not found" >&2
    exit 1
fi

ws_brief="${WORKSPACE}/context/projects/${project}/brief.md"
ralph_progress="${proj_path}/progress.md"

if [ "$direction" = "--pull" ]; then
    if [ -f "$ralph_progress" ]; then
        cp "$ralph_progress" "$ws_brief"
        echo "Pulled: progress.md -> brief.md"
    else
        echo "No progress.md found at ${ralph_progress}"
    fi
else
    if [ -f "$ws_brief" ]; then
        cp "$ws_brief" "$ralph_progress"
        echo "Pushed: brief.md -> progress.md"
    else
        echo "No brief.md found at ${ws_brief}"
    fi
fi
