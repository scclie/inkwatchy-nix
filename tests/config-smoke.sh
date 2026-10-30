#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

json="$(bash scripts/eval-config.sh tests/fixtures/valid-config.nix)"
printf '%s' "$json" | grep -Fq '"target":"Watchy_2"'
printf '%s' "$json" | grep -Fq '"DEBUG":1'
printf '%s' "$json" | grep -Fq '"SCOM_TASK":true'
printf '%s' "$json" | grep -Fq '"DEBUG_CPU_SPEED":"normalSpeed"'

default_json="$(bash scripts/eval-config.sh)"
printf '%s' "$default_json" | grep -Fq '"target":"Watchy_2"'
printf '%s' "$default_json" | grep -Fq '"defines":{}'
printf '%s' "$default_json" | grep -Fq '"rawDefines":{}'

if bash scripts/eval-config.sh tests/fixtures/invalid-config.nix >/dev/null 2>&1; then
  echo "invalid config was accepted" >&2
  exit 1
fi

echo "config evaluation: ok"
