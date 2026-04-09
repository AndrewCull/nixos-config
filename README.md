# NixOS Config

Flake-based NixOS system configuration using nixpkgs unstable, [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor), and [Stylix](https://github.com/danth/stylix) (Gruvbox Dark theming). Secrets managed with [sops-nix](https://github.com/Mic92/sops-nix).

Currently configured for one host — **ThinkPad P14s Gen 6 (AMD)**. Uses `suspend-then-hibernate` with a 2-minute s2idle window before hibernating to a swapfile (`resume_offset` configured), optimized for AMD s2idle power efficiency. A `resume-fix` systemd service rebinds all `xhci_hcd` PCI controllers and reloads `uvcvideo` + `mt7925e` after wake to recover the webcam, USB-C dock and WiFi which die during s2idle. PSR is disabled via `amdgpu.dcdebugmask=0x10` to prevent post-resume DisplayPort flicker on external monitors. Boot output is silenced for a clean greetd login prompt.

## Desktop

| Component | Program |
|-----------|---------|
| Compositor | Niri (scrollable tiling Wayland) |
| Display Manager | greetd + tuigreet (remembers username) |
| Status Bar | Waybar (with top-left Nix snowflake launcher button, square borders) |
| Launcher | Rofi (anchored top-left under the bar, square borders) |
| Notifications | Mako |
| Screen Lock | Hyprlock + swayidle |
| Wallpaper | swaybg (with rofi picker) |
| Screenshots | grim + slurp |
| Clipboard | wl-clipboard + cliphist |
| Theme | Gruvbox Dark Medium (via Stylix) |
| Icons | Papirus-Dark |
| Cursor | phinger-cursors-light |
| Fonts | JetBrains Mono (UI + terminal, Nerd Font variant) |

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
| Build/Run | just, make, watchexec, direnv |
| Search | ripgrep, fd, fzf |
| Databases | PostgreSQL (psql), TablePlus |
| Data | jq, gron, miller, csvlens |
| Monitoring | btop, bottom, dust, tokei |
| HTTP | httpie |
| Formatting | prettierd |

## Applications

| Category | Apps |
|----------|------|
| Browsers | Google Chrome (VA-API + Vulkan GPU accel), Firefox |
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
| ngrok | Tunnel local servers for demos |
| PipeWire | Audio (with PulseAudio compat) |
| TLP | Laptop power management (USB autosuspend disabled — kills xHCI on resume) |
| thermald | Thermal management |
| fprintd | Fingerprint authentication (disabled for greetd and hyprlock — fprintd timeouts blocked password entry) |
| Docker | Container runtime (auto-prune) |
| Samba + Avahi | Network file sharing / discovery |
| CUPS | Printing |
| fwupd | Firmware updates |
| Blueman | Bluetooth management |
| GNOME Keyring | Secret storage (auto-unlocks on password login) |

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

## Git Workflow

The git setup layers several tools for different contexts:

| Tool | Role |
|------|------|
| **git** (CLI) | Core version control — rebase-on-pull, auto-setup remote tracking branches |
| **[delta](https://github.com/dandavison/delta)** | Diff pager — side-by-side diffs with line numbers, gruvbox syntax highlighting |
| **[lazygit](https://github.com/jesseduffield/lazygit)** | TUI for staging, committing, branch management, and interactive rebase |
| **[gh](https://cli.github.com/)** | GitHub CLI — PRs, issues, and CI checks from the terminal (SSH protocol) |
| **[helix](https://helix-editor.com/)** | Commit message editor |

**Key settings** (`home/git.nix`):
- `pull.rebase = true` — always rebase on pull, keeping history linear
- `push.autoSetupRemote = true` — first push automatically creates the upstream tracking branch
- `init.defaultBranch = "main"`
- Delta is configured as the default pager for all git diff/log output

**Typical flow:**
1. `gs` (git status) or open lazygit to see what's changed
2. Stage and commit in lazygit
3. `gp` (git push) or push from lazygit
4. `gh pr create` to open a PR from the terminal

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
