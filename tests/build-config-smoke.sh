#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

project="$tmpdir/project"
upstream="$tmpdir/upstream"
output="$tmpdir/output"
mkdir -p "$project" "$upstream/src/defines/templates" \
  "$upstream/resources/tools/fs/templates" \
  "$upstream/resources/tools/buildTime" "$tmpdir/bin"

cat > "$project/config.nix" <<'NIX'
{
  inkwatchy = {
    defines = {
      DEBUG = 1;
      SCOM_TASK = true;
    };
    rawDefines.DEBUG_CPU_SPEED = "normalSpeed";
  };
}
NIX

cat > "$upstream/platformio.ini" <<'INI'
build_flags =
	!echo '-D GIT_COMMIT_HASH=\\"'$(git log -1 --format=%%h)'\\"'
	!echo '-D GIT_BRANCH=\\"'$(git rev-parse --abbrev-ref HEAD)'\\"'
	!echo '-D BUILD_TIME=\\"'$(date '+%%Y-%%m-%%d')'\\"'
INI

cat > "$upstream/src/defines/templates/gifnoc-template.h" <<'HEADER'
#define DEBUG 0
// #define SCOM_TASK 0
#define DEBUG_CPU_SPEED idleSpeed
HEADER
printf '#define WIFI_SSID1 ""\n' > "$upstream/src/defines/templates/laitnedifnoc-template.h"
printf 'fs\n' > "$upstream/resources/tools/fs/templates/gifnoCsf-template.ini"
printf 'partitions\n' > "$upstream/resources/tools/fs/templates/snoititrap-template.csv"
cat > "$upstream/resources/tools/buildTime/fix_esptool.py" <<'PY'
import sys

subprocess.run([
        sys.executable,
])
PY

cat > "$tmpdir/bin/pio" <<'PIO'
#!/usr/bin/env bash
set -euo pipefail

if ! grep -Fxq '#define DEBUG 1' src/defines/config.h \
  || ! grep -Fxq '#define SCOM_TASK 1' src/defines/config.h \
  || ! grep -Fxq '#define DEBUG_CPU_SPEED normalSpeed' src/defines/config.h; then
  cat src/defines/config.h >&2
  exit 1
fi
mkdir -p .pio/build/Watchy_2
printf '\351' > .pio/build/Watchy_2/firmware.bin
PIO
chmod +x "$tmpdir/bin/pio"

cd "$project"
PATH="$tmpdir/bin:$PATH" \
INKWATCHY_SRC="$upstream" \
INKWATCHY_NIX_ROOT="$root" \
INKWATCHY_NIX_PATCH_SCRIPT="$root/scripts/patch-upstream.sh" \
PLATFORMIO_PYTHONPATH=unused \
bash "$root/scripts/build-watchy2.sh" "$output"

test -s "$output/firmware.bin"
grep -Fxq 'environment=Watchy_2' "$output/build-info.txt"

echo "build config: ok"
