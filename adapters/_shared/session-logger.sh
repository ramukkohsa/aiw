#!/usr/bin/env bash
# session-logger.sh — Watches tool history files and normalizes into unified format
# Usage: bash session-logger.sh [--once]
# Without --once, runs as a background watcher.

set -euo pipefail

WORKSPACE="${HOME}/.ai-workspace"
HISTORY_DIR="${WORKSPACE}/history"
INDEX="${HISTORY_DIR}/index.jsonl"
SESSIONS_DIR="${HISTORY_DIR}/sessions"

# Ensure dirs exist
mkdir -p "$SESSIONS_DIR" "$HISTORY_DIR/sources"

# Create date-partitioned session directory
today() {
    date +%Y-%m-%d
}

session_dir() {
    local dir="${SESSIONS_DIR}/$(today)"
    mkdir -p "$dir"
    echo "$dir"
}

# Normalize a history entry into the unified format
normalize_entry() {
    local tool="$1"
    local timestamp="$2"
    local summary="$3"
    local project="${4:-unknown}"

    local entry
    entry=$(python3 -c "
import json, sys
print(json.dumps({
    'tool': sys.argv[1],
    'timestamp': sys.argv[2],
    'summary': sys.argv[3],
    'project': sys.argv[4],
    'date': sys.argv[2][:10] if len(sys.argv[2]) >= 10 else 'unknown'
}))
" "$tool" "$timestamp" "$summary" "$project")

    echo "$entry" >> "$INDEX"
}

# Snapshot current session state
snapshot_session() {
    local tool="$1"
    local project="${2:-}"
    local session_file="${WORKSPACE}/sessions/current.json"

    python3 -c "
import json
from datetime import datetime
session = {
    'tool': '''${tool}''',
    'project': '''${project}''',
    'started': datetime.now().isoformat(),
    'last_activity': datetime.now().isoformat(),
    'status': 'active'
}
with open('''${session_file}''', 'w') as f:
    json.dump(session, f, indent=2)
t = session['tool']
p = session['project']
print(f'Session recorded: {t} on {p}')
"
}

# End current session
end_session() {
    local session_file="${WORKSPACE}/sessions/current.json"
    if [ ! -f "$session_file" ]; then
        echo "No active session."
        return
    fi

    python3 -c "
import json, os
from datetime import datetime
sf = '''${session_file}'''
sd = '''${SESSIONS_DIR}'''
with open(sf) as f:
    session = json.load(f)
session['status'] = 'ended'
session['ended'] = datetime.now().isoformat()
d = session.get('started', '')[:10]
archive_dir = sd + '/' + d
os.makedirs(archive_dir, exist_ok=True)
archive_file = archive_dir + '/' + session['tool'] + '_' + datetime.now().strftime('%H%M%S') + '.json'
with open(archive_file, 'w') as f:
    json.dump(session, f, indent=2)
os.remove(sf)
print('Session ended and archived to ' + archive_file)
"
}

# ── Main ──
case "${1:-}" in
    --start)
        snapshot_session "${2:-unknown}" "${3:-}"
        ;;
    --end)
        end_session
        ;;
    --log)
        normalize_entry "${2:-unknown}" "$(date -Iseconds)" "${3:-no summary}" "${4:-unknown}"
        ;;
    *)
        echo "Usage: session-logger.sh --start <tool> [project]"
        echo "       session-logger.sh --end"
        echo "       session-logger.sh --log <tool> <summary> [project]"
        ;;
esac
