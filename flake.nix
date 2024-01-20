{
  description = "rust-nix-monorepo-template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";

    cargo2nix = {
      url = "github:cargo2nix/cargo2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, flake-utils, nixpkgs, rust-overlay, cargo2nix, ... }:
    let
      systems = [ "x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
    in
    flake-utils.lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            rust-overlay.overlays.default
            cargo2nix.overlays.default
          ];
        };

        rustVersion = "1.72.0";

        rust-toolchain = pkgs.rust-bin.stable."${rustVersion}".overrides {
          extensions = [ "rust-src" "clippy" "rustfmt" ];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          inherit rustVersion;

          packageFun = import ./Cargo.nix;
        };

        cli = (rustPkgs.workspace.cli { });
      in
      rec {
        packages = {
          inherit cli;
          default = packages.cli;
        };

        apps = {
          cli = flake-utils.lib.mkApp {
            drv = packages.cli;
          };
          default = apps.cli;
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ rust-toolchain ];
        };
      }
    );
}
