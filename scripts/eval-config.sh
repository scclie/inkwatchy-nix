#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config_path="${1:-}"

if [[ -n "$config_path" && ! -f "$config_path" ]]; then
  echo "missing config: $config_path" >&2
  exit 1
fi

cd "$root"

if [[ -n "$config_path" ]]; then
  export INKWATCHY_CONFIG_PATH="$(realpath "$config_path")"
  exec nix eval --impure --json --expr \
    'import ./lib/eval-config.nix { configPath = builtins.getEnv "INKWATCHY_CONFIG_PATH"; }'
fi

exec nix eval --impure --json --expr 'import ./lib/eval-config.nix {}'
