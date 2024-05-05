# Zigo-nix

This flake exposes an overlay that makes `buildGoModule` also take `GOOS` and `GOARCH` as arguments and use zig as a c compiler, enabling CGO builds to work cross platforms.
