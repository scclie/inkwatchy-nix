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
            export INKWATCHY_NIX_ROOT=${./.}
            export INKWATCHY_NIX_PATCH_SCRIPT=${./scripts/patch-upstream.sh}
            export PLATFORMIO_PYTHONPATH=${pkgs.platformio}/${pkgs.python3.sitePackages}
            exec ${pkgs.bash}/bin/bash ${./scripts/build-watchy2.sh} "$@"
          '';
        };
        makeCatalogueApp = name: action: pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = with pkgs; [ bash coreutils nix ];
          text = ''
            export INKWATCHY_CONFIG_TEMPLATE=${inkwatchy}/src/defines/templates/gifnoc-template.h
            export INKWATCHY_NIX_ROOT=${./.}
            exec ${pkgs.bash}/bin/bash ${./scripts/config-catalogue.sh} ${action}
          '';
        };
        initConfig = makeCatalogueApp "init-config" "init";
        updateOptionCatalogue = makeCatalogueApp "update-option-catalogue" "update";
        flashWatchy2 = pkgs.writeShellApplication {
          name = "flash-watchy2";
          runtimeInputs = with pkgs; [ bash coreutils esptool ];
          text = ''
            export INKWATCHY_NIX_ROOT=${./.}
            exec ${pkgs.bash}/bin/bash ${./scripts/flash-watchy2.sh} "$@"
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
        apps.init-config = {
          type = "app";
          program = "${initConfig}/bin/init-config";
        };
        apps.update-option-catalogue = {
          type = "app";
          program = "${updateOptionCatalogue}/bin/update-option-catalogue";
        };
        apps.flash-watchy2 = {
          type = "app";
          program = "${flashWatchy2}/bin/flash-watchy2";
        };
      });
}
