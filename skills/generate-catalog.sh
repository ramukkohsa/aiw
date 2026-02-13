#!/usr/bin/env bash
# Generate skills/catalog.json by scanning all skill sources.
# Run: bash ~/.ai-workspace/skills/generate-catalog.sh

set -euo pipefail

WORKSPACE="${HOME}/.ai-workspace"
CATALOG="${WORKSPACE}/skills/catalog.json"
PLUGIN_DIR="/mnt/c/Users/ashok.palle/.claude/skills/.claude-plugin"
RALPH_DIR="${HOME}/.agents/skills"
PROJECT_SKILL_DIR="/mnt/c/Users/ashok.palle/n8n-workflows/.claude/skills"

# Start JSON array
echo '[' > "$CATALOG"
FIRST=true

# Helper: extract name from filename (strip .md, replace hyphens)
name_from_file() {
    basename "$1" .md | sed 's/SKILL//' | sed 's/^-//' | sed 's/-$//; s/-/ /g'
}

# Helper: extract first heading or description from frontmatter
desc_from_file() {
    # Try frontmatter description first
    local desc
    desc=$(grep -m1 '^description:' "$1" 2>/dev/null | sed 's/^description:\s*//' | sed 's/^"//' | sed 's/"$//' || true)
    if [ -n "$desc" ]; then
        echo "$desc"
        return
    fi
    # Fall back to first # heading content
    desc=$(grep -m1 '^#' "$1" 2>/dev/null | sed 's/^#\+\s*//' || true)
    if [ -n "$desc" ]; then
        echo "$desc"
        return
    fi
    echo "No description"
}

# Helper: derive tags from directory path
tags_from_path() {
    local path="$1"
    local tags=""
    # Category from parent directory
    case "$path" in
        *01-core*) tags='"core", "development"' ;;
        *02-language*) tags='"language", "specialist"' ;;
        *03-infrastructure*) tags='"infrastructure", "devops"' ;;
        *04-quality*) tags='"quality", "security"' ;;
        *05-data*) tags='"data", "ai"' ;;
        *06-developer*) tags='"dx", "tooling"' ;;
        *07-specialized*) tags='"specialized"' ;;
        *08-business*) tags='"business", "product"' ;;
        *09-meta*) tags='"meta", "orchestration"' ;;
        *10-research*) tags='"research", "analysis"' ;;
        *pdi-n8n*) tags='"n8n", "pdi"' ;;
        *pdi-aws*) tags='"aws", "pdi"' ;;
        *pdi-python*) tags='"python", "pdi"' ;;
        *pdi-salesforce*) tags='"salesforce", "pdi"' ;;
        *pdi-okta*) tags='"okta", "pdi"' ;;
        *pdi-netsuite*) tags='"netsuite", "pdi"' ;;
        *pdi-core*) tags='"core", "pdi"' ;;
        *pdi-claude*) tags='"claude", "pdi"' ;;
        *pdi-development*) tags='"development", "pdi"' ;;
        *pdi-business*) tags='"business", "pdi"' ;;
        *ralph*) tags='"ralph", "tui"' ;;
        *) tags='"general"' ;;
    esac
    echo "$tags"
}

emit_entry() {
    local name="$1" desc="$2" source="$3" path="$4" tags="$5" compat="$6"
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo ',' >> "$CATALOG"
    fi
    # Escape JSON strings
    desc=$(echo "$desc" | sed 's/"/\\"/g' | tr -d '\n')
    name=$(echo "$name" | tr -d '\n')
    cat >> "$CATALOG" <<ENTRY
  {
    "name": "${name}",
    "description": "${desc}",
    "source": "${source}",
    "path": "${path}",
    "tags": [${tags}],
    "tools": [${compat}]
  }
ENTRY
}

# ── Scan Claude plugin skills ──
if [ -d "$PLUGIN_DIR" ]; then
    while IFS= read -r file; do
        [ -f "$file" ] || continue
        name=$(name_from_file "$file")
        desc=$(desc_from_file "$file")
        tags=$(tags_from_path "$file")
        emit_entry "$name" "$desc" "claude-plugin" "$file" "$tags" '"claude", "kilocode", "cline"'
    done < <(find "$PLUGIN_DIR" -name "*.md" ! -name "README.md" ! -name "CHANGELOG.md" ! -name "marketplace.json" -type f 2>/dev/null | sort)
fi

# ── Scan Ralph TUI skills ──
if [ -d "$RALPH_DIR" ]; then
    while IFS= read -r file; do
        [ -f "$file" ] || continue
        dir_name=$(basename "$(dirname "$file")")
        desc=$(desc_from_file "$file")
        emit_entry "$dir_name" "$desc" "ralph" "$file" '"ralph", "tui"' '"ralph", "claude"'
    done < <(find "$RALPH_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)
fi

# ── Scan project-level skills ──
if [ -d "$PROJECT_SKILL_DIR" ]; then
    while IFS= read -r file; do
        [ -f "$file" ] || continue
        dir_name=$(basename "$(dirname "$file")")
        desc=$(desc_from_file "$file")
        emit_entry "$dir_name" "$desc" "project" "$file" '"n8n", "project"' '"claude", "kilocode"'
    done < <(find "$PROJECT_SKILL_DIR" -name "SKILL.md" -type f 2>/dev/null | sort)

    # Also scan standalone .md skill files (not in subdirs)
    while IFS= read -r file; do
        [ -f "$file" ] || continue
        name=$(name_from_file "$file")
        desc=$(desc_from_file "$file")
        emit_entry "$name" "$desc" "project" "$file" '"n8n", "project"' '"claude", "kilocode"'
    done < <(find "$PROJECT_SKILL_DIR" -maxdepth 1 -name "*.md" ! -name "README.md" -type f 2>/dev/null | sort)
fi

# Close JSON array
echo '' >> "$CATALOG"
echo ']' >> "$CATALOG"

# Count entries
count=$(grep -c '"name"' "$CATALOG")
echo "Generated catalog with ${count} skills at ${CATALOG}"
