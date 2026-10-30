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

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

bash scripts/render-config.sh \
  tests/fixtures/config-template.h \
  tests/fixtures/valid-config.nix > "$tmpdir/config.h"

grep -Fxq '#define DEBUG 1' "$tmpdir/config.h"
grep -Fxq '#define SCOM_TASK 1' "$tmpdir/config.h"
grep -Fxq '#define DEBUG_CPU_SPEED normalSpeed' "$tmpdir/config.h"
grep -Fxq '#define LABEL "watchy"' "$tmpdir/config.h"
grep -Fxq '#define DISABLED 0' "$tmpdir/config.h"

cat > "$tmpdir/unknown.nix" <<'NIX'
{
  inkwatchy.defines.UNKNOWN = 1;
}
NIX

if bash scripts/render-config.sh \
  tests/fixtures/config-template.h \
  "$tmpdir/unknown.nix" >"$tmpdir/unknown.h" 2>"$tmpdir/error"; then
  echo "unknown define was accepted" >&2
  exit 1
fi
grep -Fq 'unknown define: UNKNOWN' "$tmpdir/error"

cat > "$tmpdir/block-only.nix" <<'NIX'
{
  inkwatchy.defines.BLOCK_ONLY = 1;
}
NIX

if bash scripts/render-config.sh \
  tests/fixtures/config-template.h \
  "$tmpdir/block-only.nix" >"$tmpdir/block-only.h" 2>"$tmpdir/error"; then
  echo "block comment define was accepted" >&2
  exit 1
fi
grep -Fq 'unknown define: BLOCK_ONLY' "$tmpdir/error"

cat > "$tmpdir/duplicate.nix" <<'NIX'
{
  inkwatchy = {
    defines.DEBUG = 1;
    rawDefines.DEBUG = "1";
  };
}
NIX

if bash scripts/render-config.sh \
  tests/fixtures/config-template.h \
  "$tmpdir/duplicate.nix" >"$tmpdir/duplicate.h" 2>"$tmpdir/error"; then
  echo "duplicate define was accepted" >&2
  exit 1
fi
grep -Fq 'duplicate define: DEBUG' "$tmpdir/error"

bash scripts/render-catalogue.sh tests/fixtures/config-template.h \
  > "$tmpdir/config.nix.example"

grep -Fxq '    target = "Watchy_2";' "$tmpdir/config.nix.example"
grep -Fxq '      # main options' "$tmpdir/config.nix.example"
grep -Fxq '      # DEBUG = 0;' "$tmpdir/config.nix.example"
grep -Fxq '      # SCOM_TASK = 0;' "$tmpdir/config.nix.example"
grep -Fxq '      # DEBUG_CPU_SPEED = "normalSpeed";' "$tmpdir/config.nix.example"
if grep -Fq 'BLOCK_ONLY' "$tmpdir/config.nix.example"; then
  echo "block comment define was catalogued" >&2
  exit 1
fi

mkdir "$tmpdir/catalogue-project"
(
  cd "$tmpdir/catalogue-project"
  INKWATCHY_CONFIG_TEMPLATE="$root/tests/fixtures/config-template.h" \
    bash "$root/scripts/config-catalogue.sh" init
  test -f config.nix.example
  printf '{}\n' > config.nix
  printf 'keep\n' > config.nix.example
  if INKWATCHY_CONFIG_TEMPLATE="$root/tests/fixtures/config-template.h" \
    bash "$root/scripts/config-catalogue.sh" init >/dev/null 2>&1; then
    echo "init overwrote config.nix" >&2
    exit 1
  fi
  grep -Fxq 'keep' config.nix.example
  INKWATCHY_CONFIG_TEMPLATE="$root/tests/fixtures/config-template.h" \
    bash "$root/scripts/config-catalogue.sh" update
  grep -Fxq '    target = "Watchy_2";' config.nix.example
)

echo "config generation: ok"
