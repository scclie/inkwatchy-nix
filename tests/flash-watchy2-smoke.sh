#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

firmware="$tmpdir/firmware.bin"
port=/dev/null
log="$tmpdir/esptool.log"
mkdir "$tmpdir/bin"
printf '\351' > "$firmware"
printf 'environment=Watchy_2\n' > "$tmpdir/build-info.txt"

cat > "$tmpdir/bin/esptool" <<'SH'
#!/usr/bin/env bash
printf '%s ' "$@" >> "$ESPTOOL_LOG"
printf '\n' >> "$ESPTOOL_LOG"
SH
chmod +x "$tmpdir/bin/esptool"

if PATH="$tmpdir/bin:$PATH" ESPTOOL_LOG="$log" \
  bash "$root/scripts/flash-watchy2.sh" --port "$port" --firmware "$firmware" \
  >/dev/null 2>&1; then
  echo "flash ran without confirm" >&2
  exit 1
fi
test ! -e "$log"

if PATH="$tmpdir/bin:$PATH" ESPTOOL_LOG="$log" \
  bash "$root/scripts/flash-watchy2.sh" \
  --port "$port" --firmware "$root/out/watchy2/firmware.bin" \
  --firmware "$root/out/watchy2/firmware.bin" --confirm \
  >/dev/null 2>&1; then
  echo "repeated firmware option was accepted" >&2
  exit 1
fi
test ! -e "$log"

PATH="$tmpdir/bin:$PATH" ESPTOOL_LOG="$log" \
  bash "$root/scripts/flash-watchy2.sh" \
  --port "$port" --firmware "$firmware" --confirm

mapfile -t calls < "$log"
test "${#calls[@]}" -eq 2
test "${calls[0]}" = "--chip esp32 --port $port chip-id "
test "${calls[1]}" = "--chip esp32 --port $port --baud 115200 write-flash 0x10000 $firmware "

: > "$log"
ESPTOOL="$tmpdir/bin/esptool" ESPTOOL_LOG="$log" \
  nix run "$root#flash-watchy2" -- \
  --port "$port" --firmware "$firmware" --confirm
mapfile -t calls < "$log"
test "${#calls[@]}" -eq 2
test "${calls[0]}" = "--chip esp32 --port $port chip-id "
test "${calls[1]}" = "--chip esp32 --port $port --baud 115200 write-flash 0x10000 $firmware "

: > "$log"
printf 'bad' > "$tmpdir/bad.bin"
if PATH="$tmpdir/bin:$PATH" ESPTOOL_LOG="$log" \
  bash "$root/scripts/flash-watchy2.sh" \
  --port "$port" --firmware "$tmpdir/bad.bin" --confirm >/dev/null 2>&1; then
  echo "invalid firmware was flashed" >&2
  exit 1
fi
test ! -s "$log"

if PATH="$tmpdir/bin:$PATH" ESPTOOL_LOG="$log" \
  bash "$root/scripts/flash-watchy2.sh" \
  --port "$firmware" --firmware "$firmware" --confirm >/dev/null 2>&1; then
  echo "regular file was accepted as port" >&2
  exit 1
fi
test ! -s "$log"

echo "flash watchy2: ok"
