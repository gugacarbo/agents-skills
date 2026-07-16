#!/usr/bin/env python3
"""
Quick validation script for skills - minimal version.

Uses PyYAML when available; otherwise a small frontmatter subset parser so
`pnpm build` does not hard-fail on environments without the package.
"""

import sys
import os
import re
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - exercised when PyYAML is absent
    yaml = None


class FrontmatterError(Exception):
    """Invalid skill frontmatter."""


def _strip_scalar(value: str):
    value = value.strip()
    if not value:
        return ""
    if value[0] in ('"', "'") and value[-1] == value[0]:
        return value[1:-1]
    if value in ("true", "True"):
        return True
    if value in ("false", "False"):
        return False
    return value


def _load_frontmatter_fallback(frontmatter_text: str) -> dict:
    """Parse common SKILL.md frontmatter without PyYAML.

    Supports flat keys, quoted/plain scalars, `>` / `|` folded blocks, and one
    level of nested mapping (e.g. metadata:).
    """
    result: dict = {}
    lines = frontmatter_text.splitlines()
    i = 0
    current_map = result
    nested_key = None

    while i < len(lines):
        raw = lines[i]
        if not raw.strip() or raw.strip().startswith("#"):
            i += 1
            continue

        indent = len(raw) - len(raw.lstrip(" "))
        line = raw.strip()

        if indent >= 2 and nested_key is not None:
            if ":" not in line:
                raise FrontmatterError(f"Invalid nested line: {raw}")
            key, _, value = line.partition(":")
            current_map[key.strip()] = _strip_scalar(value)
            i += 1
            continue

        nested_key = None
        current_map = result

        if ":" not in line:
            raise FrontmatterError(f"Invalid frontmatter line: {raw}")

        key, _, value = line.partition(":")
        key = key.strip()
        value = value.strip()

        if value in (">", "|", ">-", "|-", ">+", "|+"):
            continuation: list[str] = []
            i += 1
            while i < len(lines):
                nxt = lines[i]
                if nxt.strip() == "":
                    # Blank lines inside a folded/literal block stay in the block.
                    continuation.append("")
                    i += 1
                    continue
                if nxt.startswith("  ") or nxt.startswith("\t"):
                    continuation.append(nxt.strip())
                    i += 1
                    continue
                break
            result[key] = " ".join(part for part in continuation if part)
            continue

        if value == "":
            # Nested mapping start (e.g. metadata:)
            nested = {}
            result[key] = nested
            nested_key = key
            current_map = nested
            i += 1
            continue

        result[key] = _strip_scalar(value)
        i += 1

    return result


def load_frontmatter(frontmatter_text: str) -> dict:
    if yaml is not None:
        try:
            data = yaml.safe_load(frontmatter_text)
        except yaml.YAMLError as e:
            raise FrontmatterError(f"Invalid YAML in frontmatter: {e}") from e
    else:
        data = _load_frontmatter_fallback(frontmatter_text)

    if not isinstance(data, dict):
        raise FrontmatterError("Frontmatter must be a YAML dictionary")
    return data


def validate_skill(skill_path):
    """Basic validation of a skill"""
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith('---'):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter_text = match.group(1)

    # Parse YAML frontmatter
    try:
        frontmatter = load_frontmatter(frontmatter_text)
    except FrontmatterError as e:
        return False, str(e)

    # Define allowed properties
    ALLOWED_PROPERTIES = {'name', 'description', 'license', 'allowed-tools', 'metadata', 'compatibility'}

    # Check for unexpected properties (excluding nested keys under metadata)
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if 'name' not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if 'description' not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    # Extract name for validation
    name = frontmatter.get('name', '')
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        # Check naming convention (kebab-case: lowercase with hyphens)
        if not re.match(r'^[a-z0-9-]+$', name):
            return False, f"Name '{name}' should be kebab-case (lowercase letters, digits, and hyphens only)"
        if name.startswith('-') or name.endswith('-') or '--' in name:
            return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
        # Check name length (max 64 characters per spec)
        if len(name) > 64:
            return False, f"Name is too long ({len(name)} characters). Maximum is 64 characters."

    # Extract and validate description
    description = frontmatter.get('description', '')
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        # Check for angle brackets
        if '<' in description or '>' in description:
            return False, "Description cannot contain angle brackets (< or >)"
        # Check description length (max 1024 characters per spec)
        if len(description) > 1024:
            return False, f"Description is too long ({len(description)} characters). Maximum is 1024 characters."

    # Validate compatibility field if present (optional)
    compatibility = frontmatter.get('compatibility', '')
    if compatibility:
        if not isinstance(compatibility, str):
            return False, f"Compatibility must be a string, got {type(compatibility).__name__}"
        if len(compatibility) > 500:
            return False, f"Compatibility is too long ({len(compatibility)} characters). Maximum is 500 characters."

    return True, "Skill is valid!"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)
    
    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
