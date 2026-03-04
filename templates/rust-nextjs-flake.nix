{
  description = "Example dev environment - Rust API + Next.js frontend";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        rust-toolchain = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust
            rust-toolchain
            pkg-config
            openssl

            # Node / Next.js
            nodejs_22
            nodePackages.pnpm

            # Docker
            docker-compose

            # Database tools (if needed)
            # postgresql_16
            # redis

            # Useful dev tools
            just
            watchexec
            cargo-watch
          ];

          shellHook = ''
            echo "🦀 Rust $(rustc --version | cut -d' ' -f2)"
            echo "📦 Node $(node --version)"
            echo ""
            echo "Ready to dev. Run 'just' for available commands."
          '';

          # Environment variables for the project
          DATABASE_URL = "postgresql://localhost:5432/myapp";
          RUST_LOG = "debug";
        };
      });
}

# Usage:
# 1. Drop this flake.nix in your project root
# 2. Run `nix develop` or let direnv auto-load it
# 3. Create a .envrc with: use flake
# 4. Run `direnv allow`
#
# Now every time you cd into the project, you get the exact
# toolchain you need. No global installs, no version conflicts.
