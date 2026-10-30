#!/usr/bin/env bash
set -euo pipefail

: "${INKWATCHY_CONFIG_TEMPLATE:?INKWATCHY_CONFIG_TEMPLATE is required}"

if [[ "$#" -ne 1 || ( "$1" != init && "$1" != update ) ]]; then
  echo "usage: $0 <init|update>" >&2
  exit 2
fi

root="${INKWATCHY_NIX_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
output="$PWD/config.nix.example"

if [[ "$1" == init && -e "$PWD/config.nix" ]]; then
  echo "config.nix already exists" >&2
  exit 1
fi

temporary="$(mktemp "$PWD/.config.nix.example.XXXXXX")"
trap 'rm -f "$temporary"' EXIT
bash "$root/scripts/render-catalogue.sh" "$INKWATCHY_CONFIG_TEMPLATE" > "$temporary"
mv "$temporary" "$output"
trap - EXIT
