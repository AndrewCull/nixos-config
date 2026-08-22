---
name: nixos-config
description: >
  How to change andrew's NixOS machines safely — the flake at /etc/nixos-config
  (p14s, darkstar). Use when asked to add a package, change a keybind, tweak
  waybar/rofi/mako/niri, add a service, fix a host quirk, or "make the system
  do X". Triggers: nixos-config, rebuild, home-manager, niri config, keybinding,
  waybar, stylix, sops, flake input, new host.
---

# nixos-config

Everything about the machines lives in the flake at `/etc/nixos-config`
(also `~/nixos-config`). Nothing is configured by hand outside it; if you
change a file under `~/.config` that home-manager owns, the next rebuild
overwrites it. Read the repo's `CLAUDE.md` and `README.md` first — the README
is the changelog of quirks and the rule is that every config change updates it.

## Layout (where a change goes)

| Want to… | Edit |
|---|---|
| add a system package / service, change boot, networking, users, stylix | `modules/common.nix` (all hosts) or `hosts/<host>/configuration.nix` (one host) |
| compositor-level things (greetd, portals, PAM, bluetooth) | `modules/niri.nix` |
| keybinds, outputs, window rules, animations | `confs/niri/config.kdl` (raw KDL, not generated) |
| bar, launcher, notifications, lock/idle, wallpaper scripts | `home/niri.nix` |
| user packages, CLI tools, dev env | `home/apps.nix`, `home/dev.nix` |
| shell aliases/functions | `home/fish.nix` |
| a new home-manager concern | a new `home/<name>.nix` — auto-imported, no registration needed |
| a new agent skill | `agents/skills/<name>/SKILL.md` — symlinked into `~/.claude/skills/` by `home/ai.nix` |
| keyboard remaps | `modules/hhkb.nix` (work HHKB), `modules/mxkeys.nix` (darkstar MX Keys) |

Hosts: `p14s` (ThinkPad P14s Gen 6 AMD, laptop) and `darkstar` (AM5 desktop,
RX 9070 XT). Host-conditional home config uses `osConfig.networking.hostName`.

## Workflow

1. Edit. Keep the style of the surrounding file; comments explain *why*, with
   dates for hardware workarounds.
2. Check: `nixos-rebuild dry-build --flake /etc/nixos-config#$(hostname)`
   (or `nix flake check`). Fix evaluation errors before offering the change.
3. Apply only when asked: `rebuild` (fish function →
   `sudo nixos-rebuild switch --flake /etc/nixos-config#$(hostname)`). Needs the
   user's password — it will prompt in the terminal.
4. Update `README.md` (tables for Desktop / Terminal / Applications / System
   Services / Keybindings as appropriate). This is a repo rule, not optional.
5. Commit only when asked.

## Rules of the road

- Never edit anything under `/nix/store`, `/run/current-system`, or
  home-manager-generated files in `~/.config` — change the source and rebuild.
- Secrets go through sops-nix (`secrets.yaml`, `.sops.yaml`); never paste a
  secret into a `.nix` file. `users.mutableUsers = false` — the login password
  hash comes from sops.
- `stateVersion` is `"26.05"`; don't bump it.
- Packages come from the system nixpkgs (home-manager `useGlobalPkgs`); use the
  `nixos` MCP tool to confirm a package/option exists in `nixos-unstable`
  before adding it.
- Pins exist for reasons: niri from `niri-flake` (niri-stable), libinput 1.29.2
  via the `nixpkgs-libinput` input, herdr at a release tag. Don't "clean them up".
- Roll back is `sudo nixos-rebuild switch --rollback` or picking a previous
  generation at boot; `nixos-rebuild list-generations` shows them.
