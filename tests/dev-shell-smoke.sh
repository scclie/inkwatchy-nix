#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

nix develop --command bash -lc '
  set -euo pipefail
  test -d "$INKWATCHY_UPSTREAM"
  test -f "$INKWATCHY_UPSTREAM/platformio.ini"
  pio --version | grep -F "PlatformIO Core"
  cargo_version="$(cargo -vV | sed -n "s/^release: //p")"
  rustc_version="$(rustc --version | awk "{print \$2}")"
  test "$cargo_version" = "$rustc_version"
  python -m virtualenv --version >/dev/null
'

echo "dev shell: ok"
