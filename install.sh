#!/usr/bin/env bash
# Symlink every skill and agent in this repo into ~/.claude. Idempotent; never overwrites a real file/dir.
set -eu
KIT="$(cd "$(dirname "$0")" && pwd)"
DEST="${CLAUDE_HOME:-$HOME/.claude}"
mkdir -p "$DEST/skills" "$DEST/agents"
rc=0
# Step 1: tether (latest) + NVIDIA provider + MCP registration. swe codes through it; failures warn, never abort.
if command -v uv >/dev/null; then
  uv tool install --upgrade "tether-sdk[mcp]" >/dev/null && echo "tether   $(tether --version)" || echo "WARN     tether install failed"
else echo "WARN     uv not found (https://docs.astral.sh/uv/); tether not installed, swe will code itself"; fi
if command -v tether >/dev/null; then
  PY="${TETHER_HOME:-$HOME/.tether}/providers.yaml"; mkdir -p "$(dirname "$PY")"
  grep -q '^nvidia:' "$PY" 2>/dev/null || { printf 'nvidia:\n  kind: openai\n  base_url: https://integrate.api.nvidia.com/v1\n  api_key_env: NVIDIA_API_KEY\n' >> "$PY"; echo "added    nvidia provider to $PY"; }
  command -v claude >/dev/null && ! claude mcp get tether >/dev/null 2>&1 && claude mcp add --scope user tether -- "$(command -v tether)" mcp >/dev/null && echo "added    tether MCP server (user scope)"
  [ -n "${NVIDIA_API_KEY:-}" ] || echo "WARN     NVIDIA_API_KEY not set in this shell; export it (e.g. ~/.profile) so swe can use nvidia/z-ai/glm-5.3-flash"
fi
link() { # link <source> <target>
  if [ -L "$2" ]; then
    [ "$(readlink "$2")" = "$1" ] && { echo "ok       $2"; return; }
    ln -sfn "$1" "$2" && echo "relinked $2 -> $1"
  elif [ -e "$2" ]; then echo "SKIPPED  $2 exists and is not a symlink (move it away first)"; rc=1
  else ln -s "$1" "$2" && echo "linked   $2 -> $1"; fi
}
for d in "$KIT"/skills/*/; do link "${d%/}" "$DEST/skills/$(basename "$d")"; done
for f in "$KIT"/agents/*.md; do link "$f" "$DEST/agents/$(basename "$f")"; done
exit $rc
