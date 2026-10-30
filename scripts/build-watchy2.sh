#!/usr/bin/env bash
set -euo pipefail

: "${INKWATCHY_SRC:?INKWATCHY_SRC must point to upstream InkWatchy}"
: "${INKWATCHY_NIX_ROOT:?INKWATCHY_NIX_ROOT must point to this adapter}"
: "${INKWATCHY_NIX_PATCH_SCRIPT:?INKWATCHY_NIX_PATCH_SCRIPT must point to patch-upstream.sh}"

source "$INKWATCHY_NIX_PATCH_SCRIPT"
project_root="$PWD"

if [[ ! -f "$INKWATCHY_SRC/platformio.ini" ]]; then
  echo "missing upstream platformio.ini: $INKWATCHY_SRC/platformio.ini" >&2
  exit 1
fi

if [[ "$#" -gt 1 ]]; then
  echo "usage: $0 [output-directory]" >&2
  exit 2
fi

output_dir="${1:-$PWD/out/watchy2}"
output_dir="$(realpath -m "$output_dir")"
cache_root="$HOME/.cache/inkwatchy-nix/tmp"
mkdir -p "$cache_root"
export TMPDIR="$cache_root"
worktree="$(mktemp -d "$cache_root/inkwatchy-watchy2.XXXXXX")"
trap 'rm -rf "$worktree"' EXIT

mkdir -p "$output_dir"
cp -a --no-preserve=ownership "$INKWATCHY_SRC/." "$worktree/"
chmod -R u+w "$worktree"

config_source="$project_root/config.nix"
if [[ -f "$config_source" ]]; then
  bash "$INKWATCHY_NIX_ROOT/scripts/render-config.sh" \
    "$worktree/src/defines/templates/gifnoc-template.h" \
    "$config_source" > "$worktree/src/defines/config.h"
else
  bash "$INKWATCHY_NIX_ROOT/scripts/render-config.sh" \
    "$worktree/src/defines/templates/gifnoc-template.h" \
    > "$worktree/src/defines/config.h"
fi
if [[ ! -f "$worktree/src/defines/confidential.h" ]]; then
  cp "$worktree/src/defines/templates/laitnedifnoc-template.h" "$worktree/src/defines/confidential.h"
fi

fs_root="$worktree/resources/tools/fs"
mkdir -p "$fs_root/in" "$fs_root/out" "$fs_root/littlefs/conf" \
  "$fs_root/littlefs/other/lpcore" "$fs_root/littlefs/calendar"
touch "$fs_root/littlefs/conf/.keep" "$fs_root/littlefs/other/.keep"
printf '2543616\n' > "$fs_root/in/offset.txt"
printf '1572864\n' > "$fs_root/in/size.txt"
cp "$fs_root/templates/gifnoCsf-template.ini" "$fs_root/in/fsConfig.ini"
cp "$fs_root/templates/snoititrap-template.csv" "$fs_root/in/partitions.csv"

patch_platformio_metadata "$worktree/platformio.ini"

platformio_core="$HOME/.cache/inkwatchy-nix/platformio"
export PLATFORMIO_CORE_DIR="$platformio_core"
export PLATFORMIO_CACHE_DIR="$platformio_core/.cache"

if [[ ! -x "$platformio_core/penv/bin/python" ]] \
  || ! "$platformio_core/penv/bin/python" -c 'import pip' >/dev/null 2>&1; then
  rm -rf "$platformio_core/penv"
  python -m virtualenv --system-site-packages "$platformio_core/penv"
fi

export PYTHONEXEPATH="$platformio_core/penv/bin/python"
export PYTHONPATH="${PLATFORMIO_PYTHONPATH:?PLATFORMIO_PYTHONPATH is required}${PYTHONPATH:+:$PYTHONPATH}"

fix_esptool="$worktree/resources/tools/buildTime/fix_esptool.py"
patch_fix_esptool "$fix_esptool"

cd "$worktree"
pio run -e Watchy_2

firmware=".pio/build/Watchy_2/firmware.bin"
if [[ ! -s "$firmware" ]]; then
  echo "upstream build did not produce $firmware" >&2
  exit 1
fi

cp "$firmware" "$output_dir/firmware.bin"
{
  echo "environment=Watchy_2"
  echo "firmware_bytes=$(stat -c %s "$firmware")"
  echo "upstream_revision=nix-input"
} > "$output_dir/build-info.txt"

printf 'watchy 2 firmware: %s\n' "$output_dir/firmware.bin"
