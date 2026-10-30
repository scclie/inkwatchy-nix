#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

source scripts/patch-upstream.sh

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/platformio.ini" <<'INI'
build_flags =
	!echo '-D GIT_COMMIT_HASH=\\"'$(git log -1 --format=%%h)'\\"'
	!echo '-D GIT_BRANCH=\\"'$(git rev-parse --abbrev-ref HEAD)'\\"'
	!echo '-D BUILD_TIME=\\"'$(date '+%%Y-%%m-%%d')'\\"'
INI

patch_platformio_metadata "$tmpdir/platformio.ini"
grep -Fxq $'\t-D GIT_COMMIT_HASH=\\"nix-input\\"' "$tmpdir/platformio.ini"
grep -Fxq $'\t-D GIT_BRANCH=\\"nix-input\\"' "$tmpdir/platformio.ini"
grep -Fxq $'\t-D BUILD_TIME=\\"nix-build\\"' "$tmpdir/platformio.ini"
if grep -Fq '!echo' "$tmpdir/platformio.ini"; then
  echo "dynamic metadata was not removed" >&2
  exit 1
fi

cat > "$tmpdir/fix_esptool.py" <<'PY'
Import("env")

import importlib.metadata
import subprocess
import sys

subprocess.run([
        sys.executable,
        "-m",
        "pip",
])
PY

patch_fix_esptool "$tmpdir/fix_esptool.py"
grep -Fxq 'import os' "$tmpdir/fix_esptool.py"
grep -Fxq '        os.environ.get("PYTHONEXEPATH", sys.executable),' "$tmpdir/fix_esptool.py"

echo "upstream patches: ok"
