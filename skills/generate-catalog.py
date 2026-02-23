#!/usr/bin/env python3
"""Generate skills/catalog.json by scanning all skill sources."""

import json
import os
import re
from pathlib import Path

WORKSPACE = Path.home() / ".ai-workspace"
CATALOG = WORKSPACE / "skills" / "catalog.json"


def read_sources_from_config() -> dict[str, Path]:
    """Read skill source paths from config.toml [skills.sources.*] sections."""
    config_path = WORKSPACE / "config.toml"
    if not config_path.exists():
        return {}
    config = config_path.read_text()
    sources = {}
    for m in re.finditer(
        r'\[skills\.sources\.([\w-]+)\]\s*\n'
        r'path\s*=\s*"([^"]+)"\s*\n'
        r'type\s*=\s*"([^"]+)"',
        config,
    ):
        name, path, stype = m.group(1), m.group(2), m.group(3)
        sources[stype] = Path(path)
    return sources


SOURCES = read_sources_from_config()

CATEGORY_TAGS = {
    "01-core": ["core", "development"],
    "02-language": ["language", "specialist"],
    "03-infrastructure": ["infrastructure", "devops"],
    "04-quality": ["quality", "security"],
    "05-data": ["data", "ai"],
    "06-developer": ["dx", "tooling"],
    "07-specialized": ["specialized"],
    "08-business": ["business", "product"],
    "09-meta": ["meta", "orchestration"],
    "10-research": ["research", "analysis"],
    "pdi-n8n": ["n8n", "pdi"],
    "pdi-aws": ["aws", "pdi"],
    "pdi-python": ["python", "pdi"],
    "pdi-salesforce": ["salesforce", "pdi"],
    "pdi-okta": ["okta", "pdi"],
    "pdi-netsuite": ["netsuite", "pdi"],
    "pdi-core": ["core", "pdi"],
    "pdi-claude": ["claude", "pdi"],
    "pdi-development": ["development", "pdi"],
    "pdi-business": ["business", "pdi"],
}


def extract_description(filepath: Path) -> str:
    """Extract description from frontmatter or first heading."""
    try:
        text = filepath.read_text(encoding="utf-8", errors="replace")
    except Exception:
        return "No description"

    # Try frontmatter description
    m = re.search(r"^description:\s*[\"']?(.+?)[\"']?\s*$", text, re.MULTILINE)
    if m:
        return m.group(1).strip()

    # Fall back to first heading
    m = re.search(r"^#+\s+(.+)$", text, re.MULTILINE)
    if m:
        return m.group(1).strip()

    return "No description"


def tags_from_path(filepath: Path) -> list[str]:
    """Derive tags from directory path."""
    path_str = str(filepath)
    for key, tags in CATEGORY_TAGS.items():
        if key in path_str:
            return tags
    if "ralph" in path_str:
        return ["ralph", "tui"]
    return ["general"]


def scan_plugin_skills(base: Path) -> list[dict]:
    """Scan Claude plugin skill directory."""
    entries = []
    if not base.exists():
        return entries

    for md in sorted(base.rglob("*.md")):
        if md.name in ("README.md", "CHANGELOG.md"):
            continue
        # Use parent directory name for generic filenames, stem for descriptive ones
        if md.stem.upper() in ("SKILL", "QUICK-REFERENCE", "INDEX"):
            name = md.parent.name.replace("-", " ")
        else:
            name = md.stem.replace("-", " ")
        desc = extract_description(md)
        tags = tags_from_path(md)
        entries.append({
            "name": name,
            "description": desc,
            "source": "claude-plugin",
            "path": str(md),
            "tags": tags,
            "tools": ["claude", "kilocode", "cline"],
        })
    return entries


def scan_ralph_skills(base: Path) -> list[dict]:
    """Scan Ralph TUI skills."""
    entries = []
    if not base.exists():
        return entries

    for skill_md in sorted(base.rglob("SKILL.md")):
        name = skill_md.parent.name
        desc = extract_description(skill_md)
        entries.append({
            "name": name,
            "description": desc,
            "source": "ralph",
            "path": str(skill_md),
            "tags": ["ralph", "tui"],
            "tools": ["ralph", "claude"],
        })
    return entries


def scan_project_skills(base: Path) -> list[dict]:
    """Scan project-level skills."""
    entries = []
    if not base.exists():
        return entries

    # SKILL.md in subdirectories
    for skill_md in sorted(base.rglob("SKILL.md")):
        name = skill_md.parent.name
        desc = extract_description(skill_md)
        entries.append({
            "name": name,
            "description": desc,
            "source": "project",
            "path": str(skill_md),
            "tags": ["n8n", "project"],
            "tools": ["claude", "kilocode"],
        })

    # Standalone .md files at top level
    for md in sorted(base.glob("*.md")):
        if md.name == "README.md":
            continue
        name = md.stem.replace("-", " ")
        desc = extract_description(md)
        entries.append({
            "name": name,
            "description": desc,
            "source": "project",
            "path": str(md),
            "tags": ["n8n", "project"],
            "tools": ["claude", "kilocode"],
        })
    return entries


def main():
    catalog = []
    if "claude-plugin" in SOURCES:
        catalog.extend(scan_plugin_skills(SOURCES["claude-plugin"]))
    if "ralph-skill" in SOURCES:
        catalog.extend(scan_ralph_skills(SOURCES["ralph-skill"]))
    if "claude-project" in SOURCES:
        catalog.extend(scan_project_skills(SOURCES["claude-project"]))

    CATALOG.write_text(json.dumps(catalog, indent=2, ensure_ascii=False))
    print(f"Generated catalog with {len(catalog)} skills at {CATALOG}")


if __name__ == "__main__":
    main()
