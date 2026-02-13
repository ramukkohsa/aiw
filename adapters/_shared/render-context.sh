#!/usr/bin/env bash
# render-context.sh — Core context merger
# Usage: source render-context.sh; render_context [project_name]
# Returns merged context as stdout.

set -euo pipefail

WORKSPACE="${HOME}/.ai-workspace"

# Read a file if it exists, otherwise return empty string
read_if_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        cat "$file"
    fi
}

# Render merged context for a project (or global-only if no project specified)
render_context() {
    local project="${1:-}"
    local global_context="${WORKSPACE}/context/CONTEXT.md"
    local global_brief="${WORKSPACE}/context/brief.md"
    local global_stuck="${WORKSPACE}/context/stuck.md"
    local global_decisions="${WORKSPACE}/context/decisions.md"

    # ── Global Context ──
    if [ -f "$global_context" ]; then
        read_if_exists "$global_context"
        echo ""
    fi

    # ── Project Overlay ──
    if [ -n "$project" ]; then
        local proj_dir="${WORKSPACE}/context/projects/${project}"
        if [ -d "$proj_dir" ]; then
            echo "---"
            echo ""
            if [ -f "${proj_dir}/CONTEXT.md" ]; then
                read_if_exists "${proj_dir}/CONTEXT.md"
                echo ""
            fi
            if [ -f "${proj_dir}/brief.md" ]; then
                echo "---"
                echo ""
                read_if_exists "${proj_dir}/brief.md"
                echo ""
            fi
            if [ -f "${proj_dir}/decisions.md" ]; then
                echo "---"
                echo ""
                read_if_exists "${proj_dir}/decisions.md"
                echo ""
            fi
        fi
    fi

    # ── Global Brief (always appended) ──
    if [ -f "$global_brief" ]; then
        echo "---"
        echo ""
        read_if_exists "$global_brief"
        echo ""
    fi

    # ── Stuck Points ──
    local stuck_content
    stuck_content=$(read_if_exists "$global_stuck")
    if [ -n "$stuck_content" ] && ! echo "$stuck_content" | grep -q "^_No active blockers"; then
        echo "---"
        echo ""
        read_if_exists "$global_stuck"
        echo ""
    fi
}

# Resolve project name from a directory path
resolve_project() {
    local dir="${1:-$(pwd)}"
    local config="${WORKSPACE}/config.toml"

    if [ ! -f "$config" ]; then
        return 1
    fi

    # Check each project path in config
    for project in n8n-workflows n8n-agentic-devops n8n-devops-automation agentcore-devops-demo; do
        local proj_path
        proj_path=$(grep -A1 "\\[projects\\.${project}\\]" "$config" | grep "^path" | sed 's/.*= *"//' | sed 's/".*//')
        if [ -n "$proj_path" ] && [[ "$dir" == "$proj_path"* ]]; then
            echo "$project"
            return 0
        fi
    done

    return 1
}

# Get all project names from config
list_projects() {
    local config="${WORKSPACE}/config.toml"
    grep '^\[projects\.' "$config" | sed 's/\[projects\.\(.*\)\]/\1/'
}
