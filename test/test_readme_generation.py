#!/usr/bin/env python3
"""Tests for the README generation script."""

import importlib.util
import json
import tempfile
from pathlib import Path


def _load_generator():
    script = Path(__file__).parent.parent / "scripts" / "generate-template-readmes.py"
    spec = importlib.util.spec_from_file_location("generate_template_readmes", script)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_generate_readme_includes_create_devcontainer_usage():
    """Generated README must include create-devcontainer npm package usage."""
    gen = _load_generator()
    with tempfile.TemporaryDirectory() as tmpdir:
        template_dir = Path(tmpdir) / "my-template"
        template_dir.mkdir()

        template_data = {
            "id": "my-template",
            "version": "0.1.0",
            "name": "My Template",
            "description": "A test template.",
            "options": {
                "imageVariant": {
                    "type": "string",
                    "description": "Ubuntu version",
                    "proposals": ["jammy", "focal"],
                    "default": "jammy",
                }
            },
        }

        (template_dir / "devcontainer-template.json").write_text(json.dumps(template_data))
        readme = gen.generate_readme(template_dir)

        assert "npx @mrrobot0985/create-devcontainer" in readme
        assert "my-template" in readme


if __name__ == "__main__":
    test_generate_readme_includes_create_devcontainer_usage()
    print("PASS")
