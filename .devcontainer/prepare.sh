#!/usr/bin/env bash
set -euo pipefail

# A stable identity prevents containers from competing for shared volume ownership.
uid=$(id -u)
gid=$(id -g)
if [[ "$uid:$gid" != 1000:1000 ]]; then
  echo "Shared agent volumes require UID:GID 1000:1000; got $uid:$gid." >&2
  exit 1
fi
sudo -n true
for parent in "$HOME/.cache" "$HOME/.config" "$HOME/.local" "$HOME/.local/share"; do
  sudo -n mkdir -p "$parent"
  sudo -n chown "$uid:$gid" "$parent"
done
paths=(
  /opt/venv "$HOME/.cache/uv" "$HOME/.codex" "$HOME/.claude"
  "$HOME/.persist" "$HOME/.config/opencode" "$HOME/.local/share/opencode"
)
for path in "${paths[@]}"; do
  sudo -n mkdir -p "$path"
  # Refuse data owned by a different non-root identity, rather than chowning it back and forth.
  foreign=$(sudo -n find "$path" -xdev \( \( ! -uid 0 ! -uid "$uid" \) -o \( ! -gid 0 ! -gid "$gid" \) \) -print -quit)
  if [[ -n "$foreign" ]]; then
    echo "Incompatible owner in $path: $foreign. Align shared containers to UID:GID 1000:1000." >&2
    exit 1
  fi
  mismatch=$(sudo -n find "$path" -xdev \( ! -uid "$uid" -o ! -gid "$gid" \) -print -quit)
  if [[ -n "$mismatch" ]]; then
    sudo -n find "$path" -xdev \( ! -uid "$uid" -o ! -gid "$gid" \) -exec chown -h "$uid:$gid" {} +
  fi
  probe=$(mktemp "$path/.write-check.XXXXXX")
  rm -- "$probe"
done

# Preserve ordinary files and wrong-target symlinks, including their readable contents.
persist="$HOME/.persist/.claude.json"
target="$HOME/.claude.json"
if [[ ! -e "$persist" && ! -L "$persist" && -f "$target" ]]; then
  cp -p -- "$target" "$persist"
fi
if [[ -L "$target" && "$(readlink "$target")" == "$persist" ]]; then
  :
else
  if [[ -e "$target" || -L "$target" ]]; then
    backup="$HOME/.persist/claude.json.before-devcontainer.$(date +%s%N)"
    if [[ -L "$target" && -f "$target" ]]; then
      cp -pL -- "$target" "$backup.contents"
    fi
    mv -- "$target" "$backup"
  fi
  # Leave the destination absent on first use; Claude creates its own settings.
  ln -s -- "$persist" "$target"
fi

# The Windows workspace is a host bind mount: check access without changing host ownership.
probe=$(mktemp /workspaces/llm-training/.write-check.XXXXXX)
rm -- "$probe"
bash /workspaces/llm-training/.devcontainer/check-sandbox.sh

printf '\nContainer ready. Install the locked Python environment with:\n  bash .devcontainer/setup.sh\n'
