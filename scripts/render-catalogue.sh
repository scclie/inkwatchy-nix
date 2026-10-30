#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "usage: $0 <template>" >&2
  exit 2
fi

root="${INKWATCHY_NIX_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
template_path="$1"

if [[ ! -f "$template_path" ]]; then
  echo "missing template: $template_path" >&2
  exit 1
fi

export INKWATCHY_CONFIG_TEMPLATE="$(realpath "$template_path")"
cd "$root"
exec nix eval --impure --raw --expr '
  import ./lib/catalogue.nix {
    templatePath = builtins.getEnv "INKWATCHY_CONFIG_TEMPLATE";
  }
'
