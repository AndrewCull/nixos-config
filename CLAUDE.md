# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

NixOS flake-based system configuration for andrew's machines. Currently one host (`p14s` — ThinkPad P14s Gen 6, AMD). Uses nixpkgs unstable channel.

## Key Commands

```bash
# Rebuild system after config changes (fish alias)
rebuild    # → sudo nixos-rebuild switch --flake ~/nixos-config#(hostname)

# Update flake inputs
update     # → nix flake update ~/nixos-config

# Dry-run build (check for errors without applying)
nixos-rebuild dry-build --flake ~/nixos-config#p14s

# Clean old generations
nix-collect-garbage -d
```

## Architecture

**flake.nix** is the entry point. It wires together:
- **Flake inputs**: nixpkgs (unstable), home-manager, niri-flake, stylix
- **Shared modules** applied to all hosts: `modules/common.nix`, `modules/niri.nix`, plus niri-flake, home-manager, and stylix
- **Host-specific config** in `hosts/<hostname>/` (hardware + per-machine overrides)

**modules/** — System-level NixOS modules:
- `common.nix` — Boot, networking, users, nix settings, pipewire, stylix theming (gruvbox dark), shell
- `niri.nix` — Niri Wayland compositor setup, greetd, portals
- `docker.nix` — Docker daemon (only added to p14s)

**home/** — Home-manager modules (user-level config). `default.nix` auto-imports every `.nix` file in the directory, so adding a new file here automatically includes it. Key modules: fish, helix, niri (waybar/fuzzel/mako/swaylock/swayidle/swaybg), git, dev tools, apps, ghostty, starship, theme, zellij.

**hosts/p14s/** — Host-specific: AMD GPU, power management, fingerprint reader, lid behavior.

**templates/** — Reusable flake templates for per-project dev shells.

**confs/** — Raw config files referenced by modules.

## Conventions

- User is `andrew`, shell is fish, editor is helix (`hx`)
- The config lives at `/etc/nixos-config` (or `~/nixos-config` via alias)
- Home-manager uses `useGlobalPkgs` and `useUserPackages` — packages come from the system nixpkgs
- `home/default.nix` auto-imports all sibling `.nix` files; no need to manually add imports when creating new home modules
- `stateVersion` is `"24.11"` — do not change this

## Rules

- After every update to this configuration, revise the README.md file to include apps and configuration changes.
