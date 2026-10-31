# # inkwatchy-nix

nix wrapper for [inkwatchy](https://github.com/Szybet/InkWatchy)

requirements: linux, nix flakes, network on the first platformio build.

scope: watchy v2 *(i can’t test this on other versions ;/ )*

## ~ TODO
- [x] nix-managed inkwatchy options;
- [ ] secrets
- [x] Watchy_2 build
- [x] config.h option catalogue and config.nix overrides
- [x] flashing
- [ ] scom
- [ ] local patches
- [ ] build descriptors for other Watchy targets
- [ ] condition.h and platformio option coverage

upstream is a flake input, each build uses a temp writable copy.

## ## commands

```bash
# development environment
nix develop

# generate the commented upstream option catalogue
nix run .#init-config
cp config.nix.example config.nix # and edit it

# regenerate only the catalogue after an upstream update
nix run .#update-option-catalogue

# build
nix run .#build-watchy2
bash scripts/check-result.sh out/watchy2

# flash only the application partition at 0x10000
nix run .#flash-watchy2 -- \
  --port /dev/ttyACM0 \
  --confirm
```

## ## config

smth like:
```nix
{
  inkwatchy = {
    defines = {
      DEBUG = 1;
      SCOM_TASK = 1;
    };

    rawDefines = {
      DEBUG_CPU_SPEED = "normalSpeed";
    };
  };
}
```

`defines`: bool, int, c strings. `rawDefines`: unquoted c tokens.

without `config.nix`, upstream defaults are used.

## ## output

```text
 out
└──  watchy2
    ├──  build-info.txt
    └──  firmware.bin
```

!! flash does not erase or replace bootloader, partition table, or LittleFS.
