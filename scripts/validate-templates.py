#!/usr/bin/env python3
"""Validate all template files for structural correctness.

Checks:
- devcontainer-template.json is valid JSON
- .devcontainer/devcontainer.json is valid JSON
- .devcontainer/docker-compose.yml is valid YAML (if present)
- bootstrap.sh is executable (if present)
- All templateOption placeholders have matching options

Usage:
    python scripts/validate-templates.py
"""

import json
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("WARNING: PyYAML not installed; docker-compose.yml validation skipped")
    yaml = None

SRC_DIR = Path("src")
errors = []


def validate_template(template_dir: Path) -> None:
    json_path = template_dir / "devcontainer-template.json"
    if not json_path.exists():
        errors.append(f"{template_dir.name}: missing devcontainer-template.json")
        return

    try:
        template_data = json.loads(json_path.read_text())
    except json.JSONDecodeError as e:
        errors.append(f"{template_dir.name}: invalid JSON in devcontainer-template.json: {e}")
        return

    options = template_data.get("options", {})

    devcontainer_json = template_dir / ".devcontainer" / "devcontainer.json"
    if devcontainer_json.exists():
        try:
            dc_data = json.loads(devcontainer_json.read_text())
        except json.JSONDecodeError as e:
            errors.append(f"{template_dir.name}: invalid JSON in devcontainer.json: {e}")
            return

        # Check templateOption placeholders
        text = devcontainer_json.read_text()
        import re

        for match in re.finditer(r"\$\{templateOption:([^}]+)\}", text):
            opt_name = match.group(1)
            if opt_name not in options:
                errors.append(
                    f"{template_dir.name}: templateOption '{opt_name}' in devcontainer.json "
                    f"has no matching option in devcontainer-template.json"
                )
    else:
        errors.append(f"{template_dir.name}: missing .devcontainer/devcontainer.json")

    compose_yml = template_dir / ".devcontainer" / "docker-compose.yml"
    if compose_yml.exists():
        if yaml is not None:
            try:
                yaml.safe_load(compose_yml.read_text())
            except yaml.YAMLError as e:
                errors.append(f"{template_dir.name}: invalid YAML in docker-compose.yml: {e}")
        else:
            print(f"{template_dir.name}: docker-compose.yml present but PyYAML unavailable")

    bootstrap = template_dir / ".devcontainer" / "bootstrap.sh"
    if bootstrap.exists():
        if not bootstrap.stat().st_mode & 0o111:
            errors.append(f"{template_dir.name}: bootstrap.sh is not executable")
    else:
        errors.append(f"{template_dir.name}: missing .devcontainer/bootstrap.sh")

    # Validate option defaults
    for opt_name, opt_meta in options.items():
        if "default" not in opt_meta:
            errors.append(
                f"{template_dir.name}: option '{opt_name}' is missing a default value"
            )


def main() -> int:
    for template_dir in sorted(SRC_DIR.iterdir()):
        if not template_dir.is_dir():
            continue
        validate_template(template_dir)

    if errors:
        print("Template validation failed:", file=sys.stderr)
        for err in errors:
            print(f"  - {err}", file=sys.stderr)
        return 1

    print("All templates validated successfully.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
