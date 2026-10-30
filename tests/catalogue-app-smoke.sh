#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

cd "$tmpdir"
nix run "$root#init-config"
test -f config.nix.example
test ! -e config.nix
grep -Fxq '      # DEBUG = 0;' config.nix.example
cp config.nix.example generated-config.nix
bash "$root/scripts/eval-config.sh" generated-config.nix >/dev/null

printf '{}\n' > config.nix
printf 'keep\n' > config.nix.example
if nix run "$root#init-config" >/dev/null 2>&1; then
  echo "init overwrote config.nix" >&2
  exit 1
fi
grep -Fxq 'keep' config.nix.example

nix run "$root#update-option-catalogue"
grep -Fxq '    target = "Watchy_2";' config.nix.example

echo "catalogue apps: ok"
