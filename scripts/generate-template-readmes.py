#!/usr/bin/env python3
"""Generate and refresh template README.md files from devcontainer-template.json.

By default:
  - Creates missing README.md files from the standard template.
  - Updates the options table between ``## Options`` and the next ``##`` heading
    when it drifts from the JSON metadata.
  - Inserts a standard ``## Options`` section before ``## Usage`` when missing.
  - Syncs the version badge with the JSON ``version`` field.

Existing prose outside the options table and version badge is preserved.
Use ``--force`` to overwrite every README completely.

Usage:
    python3 scripts/generate-template-readmes.py [--check] [--force]

--check exits with a non-zero status if any README is missing or would change.
--force regenerates every README completely from the template.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

README_TEMPLATE = """# {name} ({id})

![Version](https://img.shields.io/badge/version-{version}-blue?style=flat-square)

{description}

## Options

{options_table}

## Usage

### Using the Dev Container CLI

```bash
devcontainer templates apply ghcr.io/mrrobot0985/devcontainer-templates/{id}:{version_major}
```

### Using the `create-devcontainer` helper

```bash
npx @mrrobot0985/create-devcontainer {id} ./my-project
```
"""

OPTIONS_HEADING = "## Options"
USAGE_HEADING = "## Usage"
TABLE_HEADER = "| Options Id | Description | Type | Default Value |"
TABLE_SEPARATOR = "| ----- | ----- | ----- | ----- |"
VERSION_BADGE_RE = re.compile(
    r"!\[Version\]\(https://img\.shields\.io/badge/version-[^)]+\)"
)


def _load_template_data(template_dir: Path) -> dict:
    json_path = template_dir / "devcontainer-template.json"
    if not json_path.exists():
        raise FileNotFoundError(f"{json_path} not found")
    return json.loads(json_path.read_text())


def _options_table_rows(options: dict) -> list[str]:
    rows = []
    for key, meta in options.items():
        desc = meta.get("description", "")
        typ = meta.get("type", "string")
        default = meta.get("default", "")
        if isinstance(default, bool):
            default = str(default).lower()
        elif isinstance(default, str) and not default:
            default = '""'
        elif isinstance(default, list):
            default = str(default)
        rows.append(f"| `{key}` | {desc} | {typ} | {default} |")
    return rows


def _build_options_table(options: dict) -> str:
    rows = _options_table_rows(options)
    return "\n".join([TABLE_HEADER, TABLE_SEPARATOR, *rows])


def _generate_options_table(options: dict) -> str:
    """Backward-compatible alias used by tests and callers."""
    return "\n".join(_options_table_rows(options))


def generate_readme(template_dir: Path) -> str:
    data = _load_template_data(template_dir)
    options = data.get("options", {})
    version = data.get("version", "0")
    version_major = version.split(".")[0] if version else "0"

    return README_TEMPLATE.format(
        name=data.get("name", data["id"]),
        id=data["id"],
        description=data.get("description", ""),
        options_table=_build_options_table(options),
        version=version,
        version_major=version_major,
    )


def _version_badge(version: str) -> str:
    return (
        f"![Version](https://img.shields.io/badge/version-{version}-blue?style=flat-square)"
    )


def _find_options_section(text: str) -> tuple[int, int] | None:
    """Return line indices of ``## Options`` and the following ``##`` heading."""
    lines = text.splitlines()
    start = None
    end = None
    for i, line in enumerate(lines):
        stripped = line.strip()
        if start is None and stripped == OPTIONS_HEADING:
            start = i
        elif start is not None and stripped.startswith("## "):
            end = i
            break
    if start is None:
        return None
    if end is None:
        end = len(lines)
    return start, end


def _parse_options_table(text: str) -> list[str] | None:
    """Return normalised options-table lines, or None if not parseable."""
    bounds = _find_options_section(text)
    if bounds is None:
        return None
    start, end = bounds
    lines = [
        line.strip() for line in text.splitlines()[start + 1 : end] if line.strip()
    ]
    if len(lines) < 2:
        return None
    if lines[0] != TABLE_HEADER.strip() or lines[1] != TABLE_SEPARATOR.strip():
        return None
    return lines


def _replace_options_table(text: str, expected_table: str) -> str:
    """Replace the options table in place while preserving surrounding content."""
    lines = text.splitlines(keepends=True)
    bounds = _find_options_section(text)
    if bounds is None:
        raise ValueError("options section not found")
    start, end = bounds
    table_lines = [line + "\n" for line in expected_table.split("\n")]
    new_lines = lines[: start + 1] + ["\n"] + table_lines + ["\n"] + lines[end:]
    return "".join(new_lines)


def _insert_options_section(text: str, expected_table: str) -> str:
    """Insert a standard Options section before ``## Usage``, or append it."""
    lines = text.splitlines(keepends=True)
    usage_idx = None
    for i, line in enumerate(lines):
        if line.strip() == USAGE_HEADING:
            usage_idx = i
            break

    section_lines = (
        [OPTIONS_HEADING + "\n", "\n"]
        + [line + "\n" for line in expected_table.split("\n")]
        + ["\n"]
    )
    if usage_idx is not None:
        new_lines = lines[:usage_idx] + section_lines + lines[usage_idx:]
    else:
        # Ensure trailing newline before append.
        if lines and not lines[-1].endswith("\n"):
            lines[-1] = lines[-1] + "\n"
        if lines and lines[-1].strip():
            section_lines = ["\n"] + section_lines
        new_lines = lines + section_lines
    return "".join(new_lines)


def _sync_version_badge(text: str, version: str) -> str:
    badge = _version_badge(version)
    if VERSION_BADGE_RE.search(text):
        return VERSION_BADGE_RE.sub(badge, text, count=1)
    # Insert badge after the first heading line when missing.
    lines = text.splitlines(keepends=True)
    if not lines:
        return badge + "\n\n"
    insert_at = 1
    # Skip blank lines after title.
    while insert_at < len(lines) and not lines[insert_at].strip():
        insert_at += 1
    new_lines = lines[:1] + ["\n", badge + "\n", "\n"] + lines[insert_at:]
    return "".join(new_lines)


def _options_match(text: str, options: dict) -> bool | None:
    """Return True if the README options table matches, None if not parseable."""
    table = _parse_options_table(text)
    if table is None:
        return None
    expected = [line.strip() for line in _build_options_table(options).splitlines()]
    return table == expected


def _version_badge_matches(text: str, version: str) -> bool:
    match = VERSION_BADGE_RE.search(text)
    if match is None:
        return False
    return match.group(0) == _version_badge(version)


def _refresh_readme(readme_path: Path, data: dict) -> str | None:
    """Return updated README content, or None if already in sync."""
    options = data.get("options", {})
    version = data.get("version", "0")
    expected_table = _build_options_table(options)
    text = readme_path.read_text()
    original = text

    match = _options_match(text, options)
    if match is None:
        if _find_options_section(text) is None:
            text = _insert_options_section(text, expected_table)
        else:
            # Options heading exists but table is not parseable — replace block.
            text = _replace_options_table(text, expected_table)
    elif not match:
        text = _replace_options_table(text, expected_table)

    if not _version_badge_matches(text, version):
        text = _sync_version_badge(text, version)

    if text == original:
        return None
    return text


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Generate or update template README.md files."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Report missing READMEs or drift without writing files.",
    )
    parser.add_argument(
        "--force",
        action="store_true",
        help="Regenerate every README completely.",
    )
    args = parser.parse_args()

    src_dir = Path(__file__).parent.parent / "src"
    changed = False

    for template_dir in sorted(src_dir.iterdir()):
        if not template_dir.is_dir():
            continue
        json_path = template_dir / "devcontainer-template.json"
        if not json_path.exists():
            continue

        readme_path = template_dir / "README.md"

        if args.force:
            if args.check:
                print(f"Would regenerate {readme_path}")
                changed = True
            else:
                readme_path.write_text(generate_readme(template_dir))
                print(f"Regenerated {readme_path}")
                changed = True
            continue

        if not readme_path.exists():
            if args.check:
                print(f"Would create {readme_path}")
                changed = True
            else:
                readme_path.write_text(generate_readme(template_dir))
                print(f"Created {readme_path}")
                changed = True
            continue

        data = _load_template_data(template_dir)
        updated = _refresh_readme(readme_path, data)
        if updated is None:
            continue

        if args.check:
            print(f"Drift detected in {readme_path}")
            changed = True
        else:
            readme_path.write_text(updated)
            print(f"Updated {readme_path}")
            changed = True

    # --check non-zero exit signals CI that READMEs are missing or drifted.
    return 1 if (args.check and changed) else 0


if __name__ == "__main__":
    sys.exit(main())
