#!/usr/bin/env bash
# Idempotent pre-run: check components, set up ./video-kit (project root). Prints only problems + a final status line.
# Exit 0 = ready, 1 = system packages missing (command printed), 2 = python setup failed.
set -u
KIT="${VIDEO_KIT:-$PWD/video-kit}"
missing_apt=()

need() { command -v "$1" >/dev/null 2>&1 || { echo "MISSING: $1"; missing_apt+=("$2"); }; }
need python3 python3
need ffmpeg ffmpeg
need ffprobe ffmpeg
need pkg-config pkg-config
need gcc build-essential
for lib in cairo pangocairo; do
  pkg-config --exists "$lib" 2>/dev/null || { echo "MISSING: $lib dev files"; missing_apt+=(libcairo2-dev libpango1.0-dev); }
done
[ -f /usr/include/python3*/Python.h ] 2>/dev/null || ls /usr/include/python3*/Python.h >/dev/null 2>&1 || missing_apt+=(python3-dev)
command -v blender >/dev/null 2>&1 || echo "note: blender not installed (optional, intro/outro only)"

if [ ${#missing_apt[@]} -gt 0 ]; then
  pkgs=$(printf '%s\n' "${missing_apt[@]}" | sort -u | tr '\n' ' ')
  echo "ACTION: ask the user to run: sudo apt install -y $pkgs"
  exit 1
fi

mkdir -p "$KIT/music"
if command -v uv >/dev/null 2>&1; then
  RUN="uv run --project $KIT"
  [ -f "$KIT/pyproject.toml" ] || (cd "$KIT" && uv init --bare --name video-kit >/dev/null) || exit 2
  (cd "$KIT" && uv add --quiet manim pillow) || exit 2
else
  echo "note: uv not found, using python3 venv + pip (install uv to prefer it)"
  [ -d "$KIT/.venv" ] || python3 -m venv "$KIT/.venv" || exit 2
  "$KIT/.venv/bin/pip" install -q manim pillow || exit 2
  RUN="$KIT/.venv/bin"
fi

if [ -d "$KIT/.venv" ]; then
  if command -v uv >/dev/null 2>&1; then
    uv run --project "$KIT" python -c "import manim, PIL" || exit 2
  else
    "$KIT/.venv/bin/python" -c "import manim, PIL" || exit 2
  fi
fi
# Role agents are global (~/.claude/agents, symlinked from the claude-kit repo); nothing to copy per project.
echo "READY kit=$KIT run_prefix='$RUN'"
