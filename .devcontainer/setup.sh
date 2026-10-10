#!/usr/bin/env bash
set -euo pipefail
cd /workspaces/llm-training
bash .devcontainer/prepare.sh
uv sync --locked --python /usr/local/bin/python
uv run --locked python examples/smoke.py
