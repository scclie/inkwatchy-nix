# # inkwatchy-nix

nix wrapper for [inkwatchy](https://github.com/Szybet/InkWatchy)

## ## scope

current scope: upstream `Watchy_2` build.

TODO:
- nix-managed inkwatchy options;
- secrets
- flashing
- scom
- local patches
- hardware validation for targets other than Watchy 2.

upstream is a flake input, each build uses a temporary writable copy.

## ## requirements

- nix and flakes enabled;
- network access on the first run.

!! tested only on nixos

## ## dev shell

```bash
nix develop
```

exports `$INKWATCHY_UPSTREAM` and provides `pio`, rust, and build tools.

## ## build

```bash
nix run .#build-watchy2
```

output:
```text
out/watchy2/
├── firmware.bin
└── build-info.txt
```

## ## verify output

```bash
bash scripts/check-result.sh ./out/watchy2
```

`firmware.bin` is an esp application image.
