#!/usr/bin/env bash

patch_platformio_metadata() {
  local path="$1"
  local temporary
  local line
  local replacements=0

  temporary="$(mktemp "${path}.XXXXXX")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      *'!echo '*GIT_COMMIT_HASH*)
        printf '%s\n' $'\t-D GIT_COMMIT_HASH=\\"nix-input\\"' >> "$temporary"
        ((replacements += 1))
        ;;
      *'!echo '*GIT_BRANCH*)
        printf '%s\n' $'\t-D GIT_BRANCH=\\"nix-input\\"' >> "$temporary"
        ((replacements += 1))
        ;;
      *'!echo '*BUILD_TIME*)
        printf '%s\n' $'\t-D BUILD_TIME=\\"nix-build\\"' >> "$temporary"
        ((replacements += 1))
        ;;
      *) printf '%s\n' "$line" >> "$temporary" ;;
    esac
  done < "$path"

  if [[ "$replacements" -ne 3 ]]; then
    rm -f "$temporary"
    echo "could not patch platformio metadata: $path" >&2
    return 1
  fi

  mv "$temporary" "$path"
}

patch_fix_esptool() {
  local path="$1"
  local temporary
  local line
  local replacements=0

  temporary="$(mktemp "${path}.XXXXXX")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    case "$line" in
      'import sys')
        printf '%s\n' 'import os' >> "$temporary"
        printf '%s\n' 'import sys' >> "$temporary"
        ((replacements += 1))
        ;;
      '        sys.executable,')
        printf '%s\n' '        os.environ.get("PYTHONEXEPATH", sys.executable),' >> "$temporary"
        ((replacements += 1))
        ;;
      *) printf '%s\n' "$line" >> "$temporary" ;;
    esac
  done < "$path"

  if [[ "$replacements" -ne 2 ]]; then
    rm -f "$temporary"
    echo "could not patch fix_esptool.py: $path" >&2
    return 1
  fi

  mv "$temporary" "$path"
}
