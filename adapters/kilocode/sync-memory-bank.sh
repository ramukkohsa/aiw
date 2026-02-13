#!/usr/bin/env bash
# adapters/kilocode/sync-memory-bank.sh — Bidirectional sync between workspace and memory bank
# Usage: bash sync-memory-bank.sh <project_name> [--pull|--push]
#   --pull: Copy from memory-bank -> workspace (KiloCode made changes)
#   --push: Copy from workspace -> memory-bank (default, workspace is source of truth)

set -euo pipefail

WORKSPACE="${HOME}/.ai-workspace"

project="${1:?Usage: sync-memory-bank.sh <project_name> [--pull|--push]}"
direction="${2:---push}"

config="${WORKSPACE}/config.toml"
proj_path=$(grep -A5 "\\[projects\\.${project}\\]" "$config" | grep "^path" | head -1 | sed 's/.*= *"//' | sed 's/".*//')

if [ -z "$proj_path" ] || [ ! -d "$proj_path" ]; then
    echo "Error: Project '${project}' not found" >&2
    exit 1
fi

mb_dir="${proj_path}/.kilocode/rules/memory-bank"
ws_dir="${WORKSPACE}/context/projects/${project}"

if [ ! -d "$mb_dir" ]; then
    mkdir -p "$mb_dir"
fi

# File mapping: workspace -> memory-bank
# CONTEXT.md  <-> context.md
# brief.md    <-> brief.md
# decisions.md <-> history.md

declare -A FILE_MAP=(
    ["CONTEXT.md"]="context.md"
    ["brief.md"]="brief.md"
    ["decisions.md"]="history.md"
)

sync_file() {
    local ws_name="$1"
    local mb_name="$2"
    local ws_file="${ws_dir}/${ws_name}"
    local mb_file="${mb_dir}/${mb_name}"

    if [ "$direction" = "--pull" ]; then
        # Memory bank -> workspace
        if [ -f "$mb_file" ]; then
            cp "$mb_file" "$ws_file"
            echo "  Pulled: ${mb_name} -> ${ws_name}"
        fi
    else
        # Workspace -> memory bank (default)
        if [ -f "$ws_file" ]; then
            cp "$ws_file" "$mb_file"
            echo "  Pushed: ${ws_name} -> ${mb_name}"
        fi
    fi
}

echo "Syncing memory bank for ${project} (${direction})..."
for ws_name in "${!FILE_MAP[@]}"; do
    sync_file "$ws_name" "${FILE_MAP[$ws_name]}"
done
echo "Done."
