#!/usr/bin/env python3
"""
Transpiler: converts canonical/ skills and rules into provider-specific formats.

Reads from canonical/{skills,rules,references} and generates:
- providers/codex/       → Codex SKILL.md format
- providers/kiro/        → Kiro steering + skills format
- providers/claude-code/ → Single CLAUDE.md file
- providers/copilot/     → Single copilot-instructions.md file

Run this after editing any file in canonical/.
"""

import os
import re
import shutil
from pathlib import Path

REPO_ROOT = Path(__file__).parent
CANONICAL = REPO_ROOT / "canonical"
PROVIDERS = REPO_ROOT / "providers"


def read_file(path: Path) -> str:
    """Read file content as UTF-8 string."""
    return path.read_text(encoding="utf-8")


def write_file(path: Path, content: str) -> None:
    """Write content to file, creating parent directories as needed."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """
    Split a markdown file into metadata dict and body.
    Handles multiline YAML values (description with >, triggers as list).
    """
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    frontmatter_str = parts[1].strip()
    body = parts[2].strip()

    metadata = {}
    current_key = None
    current_lines = []

    for line in frontmatter_str.split("\n"):
        # New top-level key
        top_match = re.match(r'^(\w+):\s*(.*)', line)
        if top_match and not line.startswith(" ") and not line.startswith("\t"):
            # Save previous key
            if current_key:
                metadata[current_key] = current_lines
            current_key = top_match.group(1)
            val = top_match.group(2).strip()
            if val and val != ">":
                current_lines = [val]
            else:
                current_lines = []
        elif current_key:
            current_lines.append(line)

    if current_key:
        metadata[current_key] = current_lines

    # Post-process values
    result = {}
    for key, lines in metadata.items():
        if key == "triggers":
            # Parse YAML list items
            triggers = []
            for line in lines:
                m = re.match(r'\s*-\s*"?([^"]*)"?', line)
                if m:
                    triggers.append(m.group(1).strip())
            result[key] = triggers
        else:
            # Join multiline values
            joined = " ".join(l.strip() for l in lines if l.strip())
            # Remove surrounding quotes
            joined = joined.strip('"').strip("'")
            result[key] = joined

    return result, body


# ============================================================
# CODEX PROVIDER
# ============================================================

def transpile_codex():
    """
    Generate Codex skill folders under providers/codex/.
    Each skill becomes a folder with SKILL.md and optional references/.
    """
    codex_dir = PROVIDERS / "codex"
    if codex_dir.exists():
        shutil.rmtree(codex_dir)

    skills_dir = CANONICAL / "skills"
    refs_dir = CANONICAL / "references"

    for skill_file in sorted(skills_dir.glob("*.md")):
        skill_name = skill_file.stem
        content = read_file(skill_file)
        metadata, body = parse_frontmatter(content)

        # Build Codex description with triggers
        description = metadata.get("description", f"Skill: {skill_name}")
        triggers = metadata.get("triggers", [])
        trigger_str = ""
        if triggers:
            trigger_str = " Triggers on: " + ", ".join(f'"{t}"' for t in triggers) + "."

        full_desc = description + trigger_str
        # Escape quotes for YAML
        safe_desc = full_desc.replace('"', '\\"')

        codex_content = f'---\nname: {skill_name}\ndescription: "{safe_desc}"\n---\n\n{body}\n'

        skill_dir = codex_dir / skill_name
        write_file(skill_dir / "SKILL.md", codex_content)

        # Copy references if the skill body mentions them
        if refs_dir.exists():
            ref_dest = skill_dir / "references"
            for ref_file in refs_dir.glob("*.md"):
                if ref_file.name in body:
                    ref_dest.mkdir(parents=True, exist_ok=True)
                    shutil.copy2(ref_file, ref_dest / ref_file.name)

    print(f"  [codex] Generated {len(list(codex_dir.iterdir()))} skills")


# ============================================================
# KIRO PROVIDER
# ============================================================

def transpile_kiro():
    """
    Generate Kiro steering files (from rules) and skills (from skills).
    Steering files use inclusion: auto frontmatter.
    Skills use inclusion: manual frontmatter.
    """
    kiro_dir = PROVIDERS / "kiro"
    if kiro_dir.exists():
        shutil.rmtree(kiro_dir)

    # Rules → Kiro steering (always included)
    rules_dir = CANONICAL / "rules"
    steering_dir = kiro_dir / "steering"

    for rule_file in sorted(rules_dir.glob("*.md")):
        content = read_file(rule_file)
        metadata, body = parse_frontmatter(content)

        rule_name = metadata.get("name", rule_file.stem)
        description = metadata.get("description", "")
        # Clean for YAML
        safe_desc = description.replace('"', '\\"')

        kiro_content = f'---\ninclusion: auto\ndescription: "{safe_desc}"\n---\n\n{body}\n'
        write_file(steering_dir / f"{rule_name}.md", kiro_content)

    # Skills → Kiro skills (manual inclusion)
    skills_dir = CANONICAL / "skills"
    kiro_skills_dir = kiro_dir / "skills"

    for skill_file in sorted(skills_dir.glob("*.md")):
        content = read_file(skill_file)
        metadata, body = parse_frontmatter(content)

        skill_name = metadata.get("name", skill_file.stem)
        description = metadata.get("description", "")
        safe_desc = description.replace('"', '\\"')

        kiro_content = f'---\ninclusion: manual\ndescription: "{safe_desc}"\n---\n\n{body}\n'
        write_file(kiro_skills_dir / f"{skill_name}.md", kiro_content)

    steering_count = len(list(steering_dir.glob("*.md"))) if steering_dir.exists() else 0
    skills_count = len(list(kiro_skills_dir.glob("*.md"))) if kiro_skills_dir.exists() else 0
    print(f"  [kiro] Generated {steering_count} steering + {skills_count} skills")


# ============================================================
# CLAUDE CODE PROVIDER
# ============================================================

def transpile_claude_code():
    """
    Generate a single CLAUDE.md that concatenates all rules and skill bodies.
    Claude Code reads ~/CLAUDE.md as global system instructions.
    """
    claude_dir = PROVIDERS / "claude-code"
    if claude_dir.exists():
        shutil.rmtree(claude_dir)

    sections = []
    sections.append("# Agent Instructions\n")
    sections.append("_Auto-generated from AgentSkills canonical source. Do not edit directly._\n")

    # Rules (always active)
    rules_dir = CANONICAL / "rules"
    if rules_dir.exists():
        sections.append("\n---\n\n## Rules\n")
        for rule_file in sorted(rules_dir.glob("*.md")):
            content = read_file(rule_file)
            _, body = parse_frontmatter(content)
            sections.append(f"\n{body}\n")

    # Skills (full body)
    skills_dir = CANONICAL / "skills"
    if skills_dir.exists():
        sections.append("\n---\n\n## Skills\n")
        for skill_file in sorted(skills_dir.glob("*.md")):
            content = read_file(skill_file)
            metadata, body = parse_frontmatter(content)
            skill_name = metadata.get("name", skill_file.stem)
            description = metadata.get("description", "")
            triggers = metadata.get("triggers", [])

            sections.append(f"\n### Skill: {skill_name}\n")
            sections.append(f"\n{description}\n")
            if triggers:
                sections.append(f"\nTriggers: {', '.join(triggers)}\n")
            sections.append(f"\n{body}\n")

    full_content = "\n".join(sections)
    write_file(claude_dir / "CLAUDE.md", full_content)
    print(f"  [claude-code] Generated CLAUDE.md ({len(full_content)} chars)")


# ============================================================
# COPILOT PROVIDER
# ============================================================

def transpile_copilot():
    """
    Generate copilot-instructions.md for GitHub Copilot.
    Includes rules fully + skill guardrails only (Copilot has smaller context).
    """
    copilot_dir = PROVIDERS / "copilot"
    if copilot_dir.exists():
        shutil.rmtree(copilot_dir)

    sections = []
    sections.append("# Copilot Instructions\n")
    sections.append("_Auto-generated from AgentSkills canonical source._\n")

    # Rules (full)
    rules_dir = CANONICAL / "rules"
    if rules_dir.exists():
        for rule_file in sorted(rules_dir.glob("*.md")):
            content = read_file(rule_file)
            _, body = parse_frontmatter(content)
            sections.append(f"\n{body}\n")

    # Skills (guardrails only — keep Copilot context lean)
    skills_dir = CANONICAL / "skills"
    if skills_dir.exists():
        sections.append("\n---\n\n## Workflow Skills\n")
        for skill_file in sorted(skills_dir.glob("*.md")):
            content = read_file(skill_file)
            metadata, body = parse_frontmatter(content)
            skill_name = metadata.get("name", skill_file.stem)
            description = metadata.get("description", "")

            sections.append(f"\n### {skill_name}\n")
            sections.append(f"{description}\n")

            # Extract Guardrails section
            guardrails_match = re.search(
                r'## Guardrails\n(.*?)(?=\n## |\Z)',
                body,
                re.DOTALL
            )
            if guardrails_match:
                sections.append(f"\n**Guardrails:**\n{guardrails_match.group(1).strip()}\n")

    full_content = "\n".join(sections)
    write_file(copilot_dir / "copilot-instructions.md", full_content)
    print(f"  [copilot] Generated copilot-instructions.md ({len(full_content)} chars)")


# ============================================================
# MAIN
# ============================================================

def main():
    """Run all transpilers and report results."""
    print("Transpiling canonical/ → providers/...")
    print()

    transpile_codex()
    transpile_kiro()
    transpile_claude_code()
    transpile_copilot()

    print()
    print("Done. Run install.sh --refresh to update symlinks.")


if __name__ == "__main__":
    main()
