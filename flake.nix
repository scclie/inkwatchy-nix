{
  description = "nix adapter for building upstream inkwatchy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    inkwatchy = {
      url = "github:Szybet/InkWatchy";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, inkwatchy }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python3.withPackages (ps: [ ps.virtualenv ]);
        buildWatchy2 = pkgs.writeShellApplication {
          name = "build-watchy2";
          runtimeInputs = with pkgs; [
            bash
            cmake
            coreutils
            findutils
            gcc
            git
            gnumake
            gnugrep
            libusb1
            ncurses
            ninja
            nix
            platformio
            pkg-config
            python
            rustup
            udev
            which
            zlib
          ];
          text = ''
            export INKWATCHY_SRC=${inkwatchy}
            export INKWATCHY_NIX_PATCH_SCRIPT=${./scripts/patch-upstream.sh}
            export PLATFORMIO_PYTHONPATH=${pkgs.platformio}/${pkgs.python3.sitePackages}
            exec ${pkgs.bash}/bin/bash ${./scripts/build-watchy2.sh} "$@"
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            bash
            cmake
            gcc
            git
            gnumake
            libusb1
            ncurses
            ninja
            platformio
            pkg-config
            python
            rustup
            udev
            which
            zlib
          ];

          shellHook = ''
            export INKWATCHY_UPSTREAM=${inkwatchy}
            export PLATFORMIO_CORE_DIR="$PWD/.root/.platformio"
            export PLATFORMIO_CACHE_DIR="$PLATFORMIO_CORE_DIR/.cache"
            export RUSTUP_TOOLCHAIN=esp
            echo "upstream: $INKWATCHY_UPSTREAM"
            echo "build: nix run .#build-watchy2"
          '';
        };

        apps.build-watchy2 = {
          type = "app";
          program = "${buildWatchy2}/bin/build-watchy2";
        };
      });
}
