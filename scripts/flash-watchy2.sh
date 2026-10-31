#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
usage: flash-watchy2 --port PATH --confirm [--firmware PATH]
EOF
}

root="${INKWATCHY_NIX_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
port=""
firmware="$PWD/out/watchy2/firmware.bin"
firmware_set=false
confirm=false

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --port)
      [[ -z "$port" && "$#" -ge 2 ]] || { usage >&2; exit 2; }
      port="$2"
      shift 2
      ;;
    --firmware)
      [[ "$firmware_set" == false && "$#" -ge 2 ]] \
        || { usage >&2; exit 2; }
      firmware="$2"
      firmware_set=true
      shift 2
      ;;
    --confirm)
      [[ "$confirm" == false ]] || { usage >&2; exit 2; }
      confirm=true
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$port" || "$confirm" != true ]]; then
  usage >&2
  exit 2
fi
if [[ ! -c "$port" ]]; then
  echo "port is not a character device: $port" >&2
  exit 1
fi
if [[ ! -s "$firmware" ]]; then
  echo "missing or empty firmware: $firmware" >&2
  exit 1
fi

firmware_dir="$(dirname "$firmware")"
if [[ "$(basename "$firmware")" == firmware.bin && -s "$firmware_dir/build-info.txt" ]]; then
  bash "$root/scripts/check-result.sh" "$firmware_dir"
else
  magic="$(od -An -tx1 -N1 "$firmware" | tr -d '[:space:]')"
  if [[ "$magic" != e9 ]]; then
    echo "invalid ESP image magic byte: expected e9, got ${magic:-none}" >&2
    exit 1
  fi
fi

esptool_command="${ESPTOOL:-esptool}"
"$esptool_command" --chip esp32 --port "$port" chip-id
"$esptool_command" --chip esp32 --port "$port" --baud 115200 \
  write-flash 0x10000 "$firmware"
