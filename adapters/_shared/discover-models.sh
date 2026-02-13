#!/usr/bin/env bash
# discover-models.sh — Query AWS Bedrock for latest Claude inference profiles
# Outputs JSON mapping roles (arch/code/quick/review) to model IDs.
#
# Usage:
#   bash discover-models.sh              # JSON output: {"arch": "...", "code": "...", ...}
#   bash discover-models.sh --table      # Human-readable table
#
# Requires: aws CLI configured with bedrock access, python3

set -euo pipefail

REGION="${AWS_REGION:-us-east-1}"
OUTPUT_MODE="${1:---json}"

# Fetch inference profiles from Bedrock and select best model per role
python3 - "$REGION" "$OUTPUT_MODE" << 'PYTHON_SCRIPT'
import json
import re
import subprocess
import sys

REGION = sys.argv[1]
OUTPUT_MODE = sys.argv[2]

# ── Fetch inference profiles from Bedrock ──

def fetch_profiles(region):
    """Call AWS CLI to list inference profiles."""
    try:
        result = subprocess.run(
            [
                "aws", "bedrock", "list-inference-profiles",
                "--region", region,
                "--query", "inferenceProfileSummaries[?contains(inferenceProfileId, 'us.anthropic.claude')]",
                "--output", "json",
            ],
            capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            print(json.dumps({"error": f"AWS CLI failed: {result.stderr.strip()}"}))
            sys.exit(1)
        return json.loads(result.stdout)
    except FileNotFoundError:
        print(json.dumps({"error": "AWS CLI not found. Install and configure aws CLI."}))
        sys.exit(1)
    except subprocess.TimeoutExpired:
        print(json.dumps({"error": "AWS CLI timed out after 30s."}))
        sys.exit(1)

# ── Parse model ID into structured data ──

# New naming: us.anthropic.claude-{family}-{major}-{minor?}-{date}-v{rev}:{tag}
# Examples:
#   us.anthropic.claude-opus-4-6-v1
#   us.anthropic.claude-sonnet-4-5-20250929-v1:0
#   us.anthropic.claude-haiku-4-5-20251001-v1:0
#   us.anthropic.claude-sonnet-4-20250514-v1:0
#   us.anthropic.claude-opus-4-1-20250805-v1:0
NEW_PATTERN = re.compile(
    r"us\.anthropic\.claude-"
    r"(?P<family>opus|sonnet|haiku)-"
    r"(?P<major>\d+)"
    r"(?:-(?P<minor>\d{1,2}))?"   # minor version: 1-2 digits (optional)
    r"(?:-(?P<date>\d{8}))?"      # date stamp: exactly 8 digits (optional)
    r"-v(?P<rev>\d+)"             # revision
    r"(?::(?P<tag>\d+))?"         # tag (optional)
)

# Legacy naming: us.anthropic.claude-3-{family}-{date}-v{rev}:{tag}
# Examples:
#   us.anthropic.claude-3-opus-20240229-v1:0
#   us.anthropic.claude-3-5-sonnet-20241022-v2:0
#   us.anthropic.claude-3-7-sonnet-20250219-v1:0
LEGACY_PATTERN = re.compile(
    r"us\.anthropic\.claude-"
    r"(?P<gen>\d+)"
    r"(?:-(?P<genminor>\d+))?"
    r"-(?P<family>opus|sonnet|haiku)-"
    r"(?P<date>\d{8})-v(?P<rev>\d+)"
    r"(?::(?P<tag>\d+))?"
)

def parse_model(profile_id):
    """Parse a model profile ID into (family, version_tuple, profile_id)."""
    m = NEW_PATTERN.match(profile_id)
    if m:
        family = m.group("family")
        major = int(m.group("major"))
        minor = int(m.group("minor")) if m.group("minor") else 0
        date = int(m.group("date")) if m.group("date") else 99999999  # no date = latest
        rev = int(m.group("rev"))
        # Version tuple: higher = newer
        return family, (major, minor, date, rev), profile_id

    m = LEGACY_PATTERN.match(profile_id)
    if m:
        family = m.group("family")
        gen = int(m.group("gen"))
        genminor = int(m.group("genminor")) if m.group("genminor") else 0
        date = int(m.group("date"))
        rev = int(m.group("rev"))
        # Legacy models: version 3.x maps to (3, genminor, date, rev)
        return family, (gen, genminor, date, rev), profile_id

    return None, None, profile_id

# ── Role assignment logic ──

def select_models(profiles):
    """Given Bedrock profiles, select best model per role."""
    # Collect active models by family
    families = {"opus": [], "sonnet": [], "haiku": []}

    for p in profiles:
        pid = p["inferenceProfileId"]
        status = p.get("status", "ACTIVE")
        if status != "ACTIVE":
            continue

        family, version, _ = parse_model(pid)
        if family and version:
            families.setdefault(family, []).append((version, pid))

    # Sort each family descending (newest first)
    for fam in families:
        families[fam].sort(reverse=True)

    result = {}

    # arch = newest Opus
    if families["opus"]:
        result["arch"] = families["opus"][0][1]

    # code = newest Sonnet
    if families["sonnet"]:
        result["code"] = families["sonnet"][0][1]

    # quick = newest Haiku
    if families["haiku"]:
        result["haiku"] = families["haiku"][0][1]  # temp key for table
        result["quick"] = families["haiku"][0][1]

    # review = second-newest Sonnet (cost-efficient), or same as code if only one
    if len(families["sonnet"]) >= 2:
        result["review"] = families["sonnet"][1][1]
    elif families["sonnet"]:
        result["review"] = families["sonnet"][0][1]

    return result, families

# ── Main ──

profiles = fetch_profiles(REGION)
selected, families = select_models(profiles)

if OUTPUT_MODE == "--table":
    print(f"{'Role':<10} {'Model ID':<60} {'Family':<8}")
    print("-" * 80)
    role_order = ["arch", "code", "quick", "review"]
    for role in role_order:
        mid = selected.get(role, "(none)")
        fam, _, _ = parse_model(mid) if mid != "(none)" else ("?", None, None)
        print(f"{role:<10} {mid:<60} {fam or '?':<8}")
    print()
    print("All active profiles:")
    for fam_name in ["opus", "sonnet", "haiku"]:
        for ver, pid in families.get(fam_name, []):
            marker = ""
            for role, mid in selected.items():
                if mid == pid and role in ("arch", "code", "quick", "review"):
                    marker = f"  ← {role}"
                    break
            print(f"  {pid:<60}{marker}")
elif OUTPUT_MODE == "--json":
    # Only output the four roles
    out = {k: v for k, v in selected.items() if k in ("arch", "code", "quick", "review")}
    print(json.dumps(out, indent=2))
else:
    print(f"Unknown mode: {OUTPUT_MODE}", file=sys.stderr)
    sys.exit(1)
PYTHON_SCRIPT
