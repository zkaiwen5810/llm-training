#!/usr/bin/env bash
set -euo pipefail
cd /workspaces/llm-training
command -v bwrap >/dev/null
# The current Codex CLI accepts the command directly after `sandbox`.
# Use an empty configuration directory so shared user preferences cannot bypass the check.
check_home=$(mktemp -d "$HOME/.codex-sandbox-check.XXXXXX")
allowed=$(mktemp -d /workspaces/llm-training/.sandbox-check.XXXXXX)
denied=$(mktemp -d "$HOME/.sandbox-check.XXXXXX")
trap 'rm -rf -- "$check_home" "$allowed" "$denied"' EXIT
CODEX_HOME="$check_home" codex sandbox \
  -c 'sandbox_mode="workspace-write"' \
  -c 'sandbox_workspace_write.network_access=false' -- \
  /usr/local/bin/python - "$allowed" "$denied" <<'PY'
from pathlib import Path
import socket
import errno
import sys

allowed, denied = map(Path, sys.argv[1:])
(allowed / "allowed").write_text("ok")
try:
    (denied / "forbidden").write_text("unexpected")
except OSError as error:
    if error.errno not in (errno.EACCES, errno.EPERM, errno.EROFS):
        raise
else:
    raise SystemExit("Sandbox incorrectly permitted a write outside the workspace")
try:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.settimeout(2)
        sock.connect(("127.0.0.1", 9))
except OSError as error:
    if error.errno not in (errno.EACCES, errno.EPERM, errno.EROFS):
        raise
else:
    raise SystemExit("Sandbox incorrectly permitted network access")
print("Codex sandbox passed: workspace writes allowed; outside writes and network denied.")
PY
