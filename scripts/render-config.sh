#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -gt 2 || "$#" -lt 1 ]]; then
  echo "usage: $0 <template> [config]" >&2
  exit 2
fi

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
template_path="$1"
config_path="${2:-}"

if [[ ! -f "$template_path" ]]; then
  echo "missing template: $template_path" >&2
  exit 1
fi
if [[ -n "$config_path" && ! -f "$config_path" ]]; then
  echo "missing config: $config_path" >&2
  exit 1
fi

export INKWATCHY_CONFIG_TEMPLATE="$(realpath "$template_path")"
if [[ -n "$config_path" ]]; then
  export INKWATCHY_CONFIG_PATH="$(realpath "$config_path")"
else
  export INKWATCHY_CONFIG_PATH=""
fi

cd "$root"
exec nix eval --impure --raw --expr '
  import ./lib/config.nix {
    templatePath = builtins.getEnv "INKWATCHY_CONFIG_TEMPLATE";
    configPath =
      let path = builtins.getEnv "INKWATCHY_CONFIG_PATH";
      in if path == "" then null else path;
  }
'
