{
  description = "Overlay for go cross-compilation using zig as a C toolchain";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.outputs.overlays.${system}.default
          ];
        };
      in {
        formatter = pkgs.alejandra;
        overlays.default = import ./overlay.nix;
        packages = let
          pkgBuilder = {
            GOOS,
            GOARCH,
          }:
            pkgs.buildGoModule {
              inherit GOOS GOARCH;
              src = ./example;
              vendorHash = "sha256-7hRezOBcjB2wsx/SwV519wg3Azh+0kHMcAoc9aYPM3A=";
              name = "example";
            };
        in {
          linuxExample = pkgBuilder {
            GOOS = "linux";
            GOARCH = "amd64";
          };
          macosExample = pkgBuilder {
            GOOS = "darwin";
            GOARCH = "arm64";
          };
        };
      }
    );
}
