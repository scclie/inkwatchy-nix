#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for path in flake.nix scripts/build-watchy2.sh scripts/check-result.sh README.md .gitignore; do
  test -f "$root/$path" || {
    echo "missing required file: $path" >&2
    exit 1
  }
done

grep -Fq 'github:Szybet/InkWatchy' "$root/flake.nix"
grep -Fq 'devShells.default' "$root/flake.nix"
grep -Fq 'apps.build-watchy2' "$root/flake.nix"
grep -Fq '.pio/' "$root/.gitignore"
grep -Fq 'secrets/' "$root/.gitignore"
grep -Fq 'PLATFORMIO_CORE_DIR' "$root/scripts/build-watchy2.sh"
grep -Fq 'PYTHONEXEPATH' "$root/scripts/build-watchy2.sh"
grep -Fq 'fix_esptool.py' "$root/scripts/build-watchy2.sh"
grep -Fq 'PLATFORMIO_PYTHONPATH' "$root/scripts/build-watchy2.sh"
grep -Fq 'gifnoc-template.h' "$root/scripts/build-watchy2.sh"
grep -Fq 'snoititrap-template.csv' "$root/scripts/build-watchy2.sh"
grep -Fq 'nix-input' "$root/scripts/build-watchy2.sh"
grep -Fq '2543616' "$root/scripts/build-watchy2.sh"
grep -Fq 'laitnedifnoc-template.h' "$root/scripts/build-watchy2.sh"
grep -Fq 'HOME/.cache/inkwatchy-nix/platformio' "$root/scripts/build-watchy2.sh"
grep -Fq 'HOME/.cache/inkwatchy-nix/tmp' "$root/scripts/build-watchy2.sh"

echo "flake structure: ok"
