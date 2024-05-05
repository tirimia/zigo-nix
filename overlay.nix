# Lovingly heavily inspired by https://github.com/flyx/Zicross/blob/master/go-overlay.nix
let
  zigTargetFromGo = goTarget:
    {
      "amd64-linux" = "x86_64-linux";
      "amd64-darwin" = "x86_64-macos";
      "arm64-linux" = "aarch64-linux";
      "arm64-darwin" = "aarch64-macos";
    }
    .${goTarget};
  zigReadOnlyFix = ''
    export ZIG_LOCAL_CACHE_DIR="$TMPDIR/zig-cache"
    export ZIG_GLOBAL_CACHE_DIR="$ZIG_LOCAL_CACHE_DIR"
  '';
in (
  pkgs: prev: {
    buildGoModule = {
      # target OS, or null for native
      GOOS ? null,
      # target architecture, or null for native
      GOARCH ? null,
      ...
    } @ args': let
      inherit (pkgs.lib) optionalString;
      targetRedundant = GOOS == prev.go.GOOS && GOARCH == prev.go.GOARCH;
      targetNotSet = GOOS == null && GOARCH == null;
      nativeCompilation = targetRedundant || targetNotSet;
      darwin = prev.stdenv.isDarwin;
    in (((prev.buildGoModule.override {
          go =
            prev.go
            // {
              GOOS =
                if GOOS != null
                then GOOS
                else prev.go.GOOS;
              GOARCH =
                if GOARCH != null
                then GOARCH
                else prev.go.GOARCH;
              CGO_ENABLED = true;
            };
        })
        args')
      .overrideAttrs (origAttrs:
        # Only do zig stuff if we actually cross-compile
        # TODO: look into https://zig.news/kristoff/building-sqlite-with-cgo-for-every-os-4cic todo statically linked binaries
          if nativeCompilation
          then origAttrs
          else let
            goTarget = "${origAttrs.GOARCH}-${origAttrs.GOOS}";
            zigTarget = zigTargetFromGo goTarget;
            macos_sdk = optionalString darwin "${prev.darwin.apple_sdk.MacOSX-SDK}";
          in {
            configurePhase =
              origAttrs.configurePhase
              + (
                zigReadOnlyFix
                + ''
                  ZIG_FLAGS="-target ${zigTarget}"
                  if [[ ! -z "${macos_sdk}" ]]; then
                     ZIG_FLAGS="$ZIG_FLAGS -F${macos_sdk}/System/Library/Frameworks"
                  fi
                  export CC="${pkgs.zig}/bin/zig cc $ZIG_FLAGS"
                  export CXX="${pkgs.zig}/bin/zig c++ $ZIG_FLAGS"
                  export PATH=$PATH:${pkgs.patchelf}/bin # For some reason it can't find patchelf so I am adding it to the PATH
                ''
              );
            buildPhase =
              origAttrs.buildPhase
              + ''
                mv $GOPATH/bin/''${GOOS}_$GOARCH/* $GOPATH/bin
                rmdir $GOPATH/bin/''${GOOS}_$GOARCH
              '';
          }));
  }
)
