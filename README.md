# NixOS Config

Flake-based NixOS system configuration using nixpkgs unstable, [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor), and [Stylix](https://github.com/danth/stylix) (Gruvbox Dark theming). Secrets managed with [sops-nix](https://github.com/Mic92/sops-nix).

Currently configured for one host — **ThinkPad P14s Gen 6 (AMD)**.

## Desktop

| Component | Program |
|-----------|---------|
| Compositor | Niri (scrollable tiling Wayland) |
| Display Manager | greetd + tuigreet |
| Status Bar | Waybar |
| Launcher | Rofi |
| Notifications | Mako |
| Screen Lock | Hyprlock + swayidle |
| Wallpaper | swaybg (with rofi picker) |
| Screenshots | grim + slurp |
| Clipboard | wl-clipboard + cliphist |
| Theme | Gruvbox Dark Medium (via Stylix) |
| Icons | Papirus-Dark |
| Cursor | phinger-cursors-light |
| Fonts | Inter (UI), FiraCode Nerd Font Mono (terminal) |

## Terminal & Shell

| Component | Program |
|-----------|---------|
| Terminal | Ghostty |
| Shell | Fish |
| Prompt | Starship |
| Multiplexer | Zellij |
| Editor | Helix |
| File Manager | Yazi (terminal), Nautilus (GUI) |
| Navigation | zoxide, fzf |

## Development

| Category | Tools |
|----------|-------|
| Rust | rustc, cargo, clippy, rustfmt, rust-analyzer |
| Node.js | nodejs 22, pnpm, typescript-language-server, vercel (via npm) |
| Nix | nil (LSP), nixfmt |
| Git | git, gh (GitHub CLI), delta (diffs), lazygit |
| Containers | Docker, dive (image explorer) |
| Build/Run | just, watchexec, direnv |
| Search | ripgrep, fd, fzf |
| Databases | PostgreSQL (psql), TablePlus |
| Data | jq, gron, miller, csvlens |
| Monitoring | btop, bottom, dust, tokei |
| HTTP | httpie |
| Formatting | prettierd |

## Applications

| Category | Apps |
|----------|------|
| Browsers | Google Chrome, Firefox |
| Email | Superhuman (PWA) |
| Chat | Slack, Teams, Zoom |
| AI | Claude (PWA) |
| Notes | Obsidian |
| Office | LibreOffice |
| PDF | zathura (viewer), xournalpp (annotation) |
| Video | mpv, OBS Studio |
| Images | imv |
| Music | Spotify |
| Passwords | Bitwarden |
| Graphics | Graphite (vector editor) |
| Code | Zed, Warp Terminal |
| Gaming | Steam + Gamescope + GameMode |

## System Services

| Service | Purpose |
|---------|---------|
| Tailscale + Trayscale | VPN / mesh networking + GUI control |
| PipeWire | Audio (with PulseAudio compat) |
| TLP | Laptop power management |
| thermald | Thermal management |
| fprintd | Fingerprint authentication |
| Docker | Container runtime (auto-prune) |
| Samba + Avahi | Network file sharing / discovery |
| CUPS | Printing |
| fwupd | Firmware updates |
| Blueman | Bluetooth management |
| GNOME Keyring | Secret storage |

## Structure

```
flake.nix                       # Entry point — inputs, shared modules, hosts
modules/
  common.nix                    # Boot, networking, users, nix settings, pipewire, stylix
  niri.nix                      # Niri compositor, greetd, portals, bluetooth
  hhkb.nix                      # HHKB keyboard layer (media/nav keys via keyd)
  docker.nix                    # Docker daemon (opt-in per host)
home/
  default.nix                   # Auto-imports all .nix files in this directory
  fish.nix                      # Shell config and aliases
  helix.nix                     # Editor + LSP setup
  niri.nix                      # Waybar (tailscale, memory, network, bt, audio, battery), rofi, mako, swayidle, hyprlock, wallpaper
  apps.nix                      # Browsers, GUI apps, PWA shortcuts
  dev.nix                       # CLI dev tools
  git.nix                       # Git config
  ghostty.nix                   # Terminal emulator
  ssh.nix                       # SSH client config
  starship.nix                  # Prompt
  theme.nix                     # Stylix overrides, icons, cursor
  zellij.nix                    # Terminal multiplexer
hosts/
  p14s/
    configuration.nix           # ThinkPad P14s: AMD GPU, TLP, fingerprint, lid, gaming
    hardware-configuration.nix  # Auto-generated hardware config
secrets/
  secrets.yaml                  # Encrypted secrets (sops-nix + age)
confs/
  niri/config.kdl               # Niri keybindings and layout
  hyprlock.conf                 # Lock screen appearance
templates/
  rust-nextjs-flake.nix         # Dev shell template: Rust + Next.js + Docker
.sops.yaml                      # sops-nix encryption rules
```

## Flake Inputs

| Input | Purpose |
|-------|---------|
| [nixpkgs](https://github.com/NixOS/nixpkgs) (unstable) | System packages |
| [home-manager](https://github.com/nix-community/home-manager) | User-level config |
| [stylix](https://github.com/danth/stylix) | Consistent theming |
| [sops-nix](https://github.com/Mic92/sops-nix) | Secrets management |

## Getting Started

### Prerequisites

- NixOS with flakes enabled
- Git

### Install

```bash
# Clone the repo
git clone https://github.com/<your-username>/nixos-config /etc/nixos-config

# Generate your hardware config
sudo nixos-generate-config --show-hardware-config > /etc/nixos-config/hosts/p14s/hardware-configuration.nix

# Set up secrets (age key + encrypted password)
sudo mkdir -p /var/lib/sops-nix
sudo age-keygen -o /var/lib/sops-nix/key.txt
# Add the public key to .sops.yaml, then:
mkpasswd -m sha-512    # generate your password hash
sops secrets/secrets.yaml   # add: andrew-password: "$6$..."

# Review and adjust:
#   - Hostname in hosts/p14s/configuration.nix
#   - Username/timezone in modules/common.nix
#   - Monitor outputs in confs/niri/config.kdl
#   - Git identity in home/git.nix

# Build and switch
sudo nixos-rebuild switch --flake /etc/nixos-config#p14s
```

### Day-to-Day

```bash
rebuild          # Rebuild and switch to new config
update           # Update flake inputs (nixpkgs, home-manager, etc.)

# Dry run — check for errors without applying
nixos-rebuild dry-build --flake /etc/nixos-config#p14s

# Clean old generations
nix-collect-garbage -d
```

### Per-Project Dev Environments

```bash
cd ~/projects/my-app
cp /etc/nixos-config/templates/rust-nextjs-flake.nix flake.nix
echo "use flake" > .envrc
direnv allow
```

## Adding a New Host

1. Create `hosts/<hostname>/` with `configuration.nix` and `hardware-configuration.nix`
2. Add the host to `flake.nix` under `nixosConfigurations`
3. Use `sharedModules` and add any host-specific modules

## Adding Home-Manager Modules

Drop a new `.nix` file in `home/` — it's automatically imported by `home/default.nix`. No need to touch any imports.

## Keybindings (Niri)

All keybindings use `Mod` (Super/Windows key). Press `Mod+Shift+/` to open the keybindings cheat sheet in Rofi.

| Key | Action |
|-----|--------|
| `Mod+Return` / `Mod+T` | Terminal (Ghostty) |
| `Mod+D` | App launcher (Rofi) |
| `Mod+E` | File manager (Yazi) |
| `Mod+Q` | Close window |
| `Mod+Escape` | Power menu |
| `Mod+H/J/K/L` | Focus left/down/up/right |
| `Mod+Ctrl+H/J/K/L` | Move window |
| `Mod+Shift+H/J/K/L` | Focus monitor |
| `Mod+1-9` | Switch workspace |
| `Mod+Ctrl+1-9` | Move window to workspace |
| `Mod+F` | Maximize column |
| `Mod+Shift+F` | Fullscreen |
| `Mod+C` | Center column |
| `Mod+R` | Cycle preset widths (1/3, 1/2, 2/3) |
| `Mod+V` | Toggle floating |
| `Mod+Tab` | Overview |
| `Mod+Shift+W` | Wallpaper picker |
| `Print` | Screenshot |
| `Mod+Shift+E` | Quit niri |

## Shell Aliases

| Alias | Command |
|-------|---------|
| `gs` | `git status` |
| `gp` | `git push` |
| `gc` | `git commit` |
| `gd` | `git diff` |
| `dc` | `docker compose` |
| `dcu` / `dcd` / `dcl` | `docker compose up -d` / `down` / `logs -f` |
| `ll` | `eza -la --icons` |
| `lt` | `eza -la --icons --tree --level=2` |
| `cat` | `bat` |
| `cd` | `z` (zoxide) |

## License

Feel free to use, modify, and share.
