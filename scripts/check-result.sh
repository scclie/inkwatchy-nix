#!/usr/bin/env bash
set -euo pipefail

if [[ "$#" -ne 1 ]]; then
  echo "usage: $0 <watchy2-output-directory>" >&2
  exit 2
fi

output_dir="$1"
firmware="$output_dir/firmware.bin"
metadata="$output_dir/build-info.txt"

if [[ ! -s "$firmware" ]]; then
  echo "missing or empty firmware: $firmware" >&2
  exit 1
fi

magic="$(od -An -tx1 -N1 "$firmware" | tr -d '[:space:]')"
if [[ "$magic" != "e9" ]]; then
  echo "invalid ESP image magic byte: expected e9, got ${magic:-none}" >&2
  exit 1
fi

if [[ ! -s "$metadata" ]]; then
  echo "missing or empty build metadata: $metadata" >&2
  exit 1
fi

if ! grep -Fxq 'environment=Watchy_2' "$metadata"; then
  echo "build metadata does not identify Watchy_2" >&2
  exit 1
fi

printf 'valid watchy 2 firmware: %s\n' "$firmware"
