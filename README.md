# NixOS Config

Flake-based NixOS system configuration using nixpkgs unstable, [Niri](https://github.com/YaLTeR/niri) (scrollable tiling Wayland compositor), and [Stylix](https://github.com/danth/stylix) (Gruvbox Dark Medium, dark polarity — image-derived palette is wired up but disabled while the wallpaper is near-monochrome). Secrets managed with [sops-nix](https://github.com/Mic92/sops-nix).

Currently configured for one host — **ThinkPad P14s Gen 6 (AMD)**. MacBook-style lid behavior: on AC or when docked the lid close is ignored (clamshell / external-monitor mode); on battery it goes straight to hibernate, writing an image to a swapfile (`resume_offset` configured) to avoid the significant drain of AMD s2idle. A `resume-fix` systemd service rebinds all `xhci_hcd` PCI controllers and reloads `uvcvideo` + `mt7925e` after wake to recover the webcam, USB-C dock and WiFi which die during s2idle. A companion `wifi-pre-sleep` service unloads `mt7925e` *before* any sleep — hibernating with a live association leaves stale entries on the mt76 wcid poll list, and the next AP roam would panic the kernel (`list_add corruption` in `mt76_wcid_add_poll`). PSR is disabled via `amdgpu.dcdebugmask=0x10` to prevent post-resume DisplayPort flicker on external monitors. The BenQ monitor's Realtek `0bda:5420` hub gets `usbcore.quirks=...:k` (no-LPM) to stop a re-enumeration loop that swamped i2c-hid and froze the touchpad while docked. Boot output is silenced for a clean greetd login prompt.

## Desktop

| Component | Program |
|-----------|---------|
| Compositor | Niri (scrollable tiling Wayland) |
| Display Manager | greetd + tuigreet (remembers username) |
| Status Bar | Waybar (top-left Nix snowflake launcher, square borders, background tinted from the current wallpaper's dominant color) |
| Launcher | Rofi (anchored top-left under the bar, square borders) |
| Notifications | Mako |
| Polkit Agent | hyprpolkitagent (GUI auth prompts for fprintd, etc.) |
| Screen Lock | Hyprlock + swayidle (locks at 15 min idle, powers off monitors 5 min after lock) |
| Wallpaper | swaybg (rofi picker + wallpaper-colorize extracts a dominant color for waybar on each change) |
| Night Mode | wlsunset (eDP-1 only, 4000K night / 6500K day, 20:00–07:00) |
| Screenshots | grim + slurp |
| Clipboard | wl-clipboard + cliphist |
| AI tooling | `sys-doctor` (`Mod+Shift+D`): gathers an evidence bundle (journal errors/warnings, kernel log, failed units, coredumps, thermal, memory/PSI, disk, battery, network + tailscale, `wpctl status`, niri outputs, top processes; `--last-boot` adds the previous boot, pstore and /var/crash) into `~/.cache/sys-doctor/<ts>/` and opens Claude Code in it with the `nixos-doctor` skill. `--quick` runs `claude -p` (Opus by default, `SYS_DOCTOR_MODEL` overrides; interactive mode uses the session default) with read-only tools and posts the `VERDICT:` line as a notification ("Open report" → glow). `sys-doctor-boot-check` (user service) offers "Diagnose with AI" on the first login after a boot that did not end cleanly. Agent skills live in `agents/skills/` (`nixos-doctor`, `nixos-config`) and are symlinked into `~/.claude/skills/` by `home/ai.nix` (out-of-store, so edits are live). |
| Theme | Gruvbox Dark Medium (via Stylix) |
| Icons | Papirus-Dark |
| Cursor | phinger-cursors-light |
| Fonts | Inter (sans-serif) + JetBrains Mono Nerd Font (monospace/terminal) |

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
| Python | uv (Astral — package/project manager) |
| Nix | nil (LSP), nixfmt |
| Git | git, gh (GitHub CLI), delta (diffs), lazygit |
| Containers | Docker, dive (image explorer) |
| Build/Run | just, make, watchexec, direnv |
| Search | ripgrep, fd, fzf |
| Databases | PostgreSQL (psql), TablePlus |
| Data | jq, gron, miller, csvlens |
| Monitoring | btop (ROCm build — AMD GPU box shown by default: util, VRAM, temp, power; plus swap/disks/IO), amdgpu_top (per-process VRAM, clocks, power), bottom, dust, tokei |
| HTTP | httpie |
| Secrets | sops (edit `secrets.yaml`), age (keygen/encryption) |
| Payments | stripe-cli (`stripe`) |
| AI agents | herdr (agent multiplexer TUI, via flake input pinned to a release tag) |
| Formatting | prettierd |

## Applications

| Category | Apps |
|----------|------|
| Browsers | Google Chrome (Wayland + VA-API hardware video decode/encode; on darkstar forced to `--force-device-scale-factor=1.25` so its UI keeps physical size at the RD320U's native-4K niri scale 1.0), Firefox |
| Email | Proton Mail (desktop), Superhuman (PWA) |
| Chat | Slack, Teams (`teams-for-linux`; Chrome managed policy auto-launches `msteams:` meeting links into the app), Zoom |
| AI | Claude (PWA) |
| Notes | Obsidian |
| Office | LibreOffice |
| PDF | zathura (viewer), xournalpp (annotation) |
| Video | mpv, OBS Studio |
| Images | imv |
| Music | Spotify, cava (terminal audio visualizer) |
| Passwords | Bitwarden |
| Graphics | Graphite (vector editor), Inkscape (vector editor), GIMP (raster editor) |
| Code | Zed, Warp Terminal |
| Gaming | darkstar only: Steam + Gamescope + GameMode, X-Plane 12 (via custom `xplane-run` FHS env), `steam-run`. Removed from p14s to reclaim disk space. |

## System Services

| Service | Purpose |
|---------|---------|
| Tailscale + Trayscale | Mesh networking (work tailnet incl. Render) + GUI control. Configured as exit-node client (`useRoutingFeatures = "client"`) so Mullvad add-on or self-hosted exit nodes route general internet traffic while tailnet peers stay reachable. Tailscale SSH enabled (`--ssh --operator=andrew`): SSH between tailnet peers is ACL-authed, no key management. |
| ngrok | Tunnel local servers for demos |
| PipeWire | Audio (with PulseAudio compat). `pavucontrol` (per-app routing GUI, also waybar volume right-click) and `pactl` (from the `pulseaudio` client tools) are on PATH. |
| Sink switching | `audio-mode` (`Mod+P` / `Mod+Shift+P`) is the fast path and behaves identically on both hosts: headphones → the connected Bluetooth device, speaker → the built-in ALC257 on p14s and the powered speakers on the rear line-out on darkstar (both reached by the same "first non-HDMI alsa sink" fallback). `sink-picker` (`Mod+O`, or left-click the waybar volume) is the general one — a rofi list of every sink, which is how you reach the BenQ's HDMI audio on darkstar. It sets the default *and* runs `pactl move-sink-input` over live streams; that move matters, since `set-default` only affects streams that start *later*, so switching output while audio plays otherwise looks like it did nothing. |
| Clipboard history | `services.cliphist` (home-manager) runs the `wl-paste --watch` daemons for text and images under `graphical-session.target`. Needed because a Wayland selection is owned by the app that set it and vanishes when that app closes — `wl-clipboard` alone keeps no history. Recall with `Mod+Ctrl+V` (`clip-picker`: rofi list → `cliphist decode` → `wl-copy`, re-copying images with their real MIME type rather than the `[[ binary data ]]` preview text). Wipe with `cliphist wipe`; clear the live selection with `wl-copy --clear` (add `--primary` for the middle-click one). |
| EasyEffects | **p14s only** (`services.easyeffects.enable = hostName == "p14s"`). Speaker DSP — background service that restores the loudness/body the P14s G6 speakers get from their Windows Dolby tuning; without it the ALC257 output is audible but quiet/thin even at 100%. Chain (tuned in the GUI, persisted by EasyEffects): autogain → convolver → stereo_tools, using the community P14s **G5** impulse response (`confs/easyeffects/`). No preset is force-loaded, so GUI tweaks survive restarts. Because its convolver is a *speaker* impulse response (wrong for headphones), the `audio-mode` helper (`Mod+P` / `Mod+Shift+P`) stops the service when switching to Bluetooth and restarts it for speakers. It is gated off on darkstar: that IR is a laptop-speaker correction, wrong for the powered desk speakers on that host, so `audio-mode` skips the start/stop there (`manage_ee=0`). |
| TLP | Laptop power management (`amd-pstate-epp` driver: `powersave` governor on AC + BAT — the *dynamic* governor in active mode; AC uses `balance_performance` EPP, BAT uses `power`. USB autosuspend disabled — kills xHCI on resume) |
| thermald | Thermal management |
| fprintd | Fingerprint authentication (disabled for greetd and hyprlock — fprintd timeouts blocked password entry) |
| Docker | Container runtime (auto-prune) |
| Samba + Avahi | Network file sharing / discovery |
| CUPS | Printing |
| SANE | Scanning — `sane-airscan` backend for driverless eSCL/AirScan (network Xerox & other MFPs auto-discovered via Avahi); `simple-scan` GUI; user in `scanner`/`lp` groups |
| fwupd | Firmware updates |
| AppImage | `programs.appimage` with binfmt — run `.AppImage` files directly |
| i2c | `hardware.i2c.enable` + user in `i2c` group — DDC/CI access for external monitor tools (e.g. BenQ Display Pilot 2) |
| OpenRGB | RGB lighting control for the Sapphire RX 9070 (darkstar only) — `motherboard = "amd"` loads the I2C modules needed to reach the GPU's controller. Set a profile in the GUI, then point `startupProfile` at it to auto-apply on boot. |
| GPU diagnostics | `glxinfo` (mesa-demos), `vulkaninfo` (vulkan-tools) and `vainfo` (libva-utils) for OpenGL/Vulkan/VA-API renderer sanity checks (darkstar only) |
| Audio routing (darkstar) | darkstar has three HDA cards: the RX 9070's HDMI/DP audio (`pci-0000_03_00.1`, the one the BenQ RD320U is actually on), the Granite Ridge iGPU's HDMI audio (`pci-0000_7c_00.1`, nothing plugged in) and the motherboard analog codec (`pci-0000_7c_00.6`). With nothing connected to the latter two, every one of their normal profiles reports `available: no`, so WirePlumber can fall back to their `pro-audio` profile — which exposes each raw HDMI pin as a sink regardless of whether a display is attached — and pin one as the default. Playing into a link-less HDMI pin gives no sound *and* slow-motion/garbled video in Chrome and Teams, because both slave the video clock to the audio sink. Fix is to pin the profiles (`7c_00.1` → `off`, `7c_00.6` → `output:analog-stereo+input:analog-stereo`) and the default sink to `alsa_output.pci-0000_03_00.1.hdmi-stereo-extra3`. Verify with `wpctl status` (streams should read `BenQ RD320U:playback_FL/FR`) and `/proc/asound/card*/eld*` (`monitor_present 1` marks the live pin). WirePlumber persists this in `~/.local/state/wireplumber/{default-profile,default-nodes}`, so a bad choice sticks across reboots until those are cleared. |
| Hang forensics (darkstar) | darkstar hard-locked on 2026-08-11 with no trace at all — journal cut off mid-line, `/sys/fs/pstore` empty, no OOM/MCE/GPU-reset/thermal event — then sat dead ~8h because nothing was watching. Leading suspect is the memory OC (2×48 GiB dual-rank G.Skill F5-6000J3036F48G trained at 5600 MT/s, above AMD's qualified ceiling for two dual-rank UDIMMs on AM5); that fix is BIOS-side (drop to 5200, or raise VSOC ≈1.25 V / VDDIO ≈1.2 V and confirm FCLK 2000 MHz). The config side makes the next one survivable: `systemd.settings.Manager.RuntimeWatchdogSec = "30s"` finally arms the board's SP5100 TCO watchdog at `/dev/watchdog` (30s without userspace scheduling → hardware reset); `kernel.panic = 10` / `panic_on_oops = 1` / `hardlockup_panic = 1` turn halt-forever into reboot-and-dump; `boot.crashDump.enable` with 512M reserved kexecs a crash kernel for a real `/proc/vmcore`. Caveat: `boot.crashDump` also forces `softlockup_panic=1` kernel-wide, so a >20s CPU stall (heavy NVMe/docker IO can do it) reboots too — drop that one option if it causes spurious reboots, the watchdog and sysctls are independent. Note a true hard lockup still leaves pstore empty; that silence is itself the confirming datum. |
| Memtest86+ | `boot.loader.systemd-boot.memtest86.enable` (darkstar) — memory test from the boot menu. Will not reproduce an idle-hours AM5 lockup; only uptime tests that. |
| Blueman | Bluetooth management |
| GNOME Keyring | Secret storage (auto-unlocks on password login) |

## Structure

```
flake.nix                       # Entry point — inputs, shared modules, hosts
modules/
  common.nix                    # Boot, networking, users, nix settings, pipewire, stylix
  niri.nix                      # Niri compositor, greetd, portals, bluetooth
  hhkb.nix                      # HHKB keyboard layer (media/nav keys via keyd)
  mxkeys.nix                    # Logitech MX Keys: Cmd → Super remap (via keyd)
  docker.nix                    # Docker daemon (opt-in per host)
home/
  default.nix                   # Auto-imports all .nix files in this directory
  ai.nix                        # sys-doctor (evidence bundle → Claude Code), boot-check service, skills symlinks
  fish.nix                      # Shell config and aliases
  helix.nix                     # Editor + LSP setup
  niri.nix                      # Waybar (tailscale, memory, network, bt, audio, battery — battery omitted on darkstar, a desktop with none), rofi, mako, swayidle, hyprlock, wallpaper
  apps.nix                      # Browsers, GUI apps, PWA shortcuts
  cava.nix                      # Terminal audio visualizer (pipewire input)
  dev.nix                       # CLI dev tools (sets CLAUDE_CODE_DISABLE_MOUSE=1 — Claude Code's mouse tracking conflicts with zellij, causing click-to-paste)
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
  niri/config.kdl               # Niri keybindings and layout (numlock enabled at startup)
  hyprlock.conf                 # Lock screen appearance
agents/
  skills/nixos-doctor/SKILL.md  # Agent skill: diagnose a sys-doctor evidence bundle
  skills/nixos-config/SKILL.md  # Agent skill: how to change this repo safely
templates/
  rust-nextjs-flake.nix         # Dev shell template: Rust + Next.js + Docker
.github/
  dependabot.yml                # Keeps the workflow's action pins current
  workflows/update-flake-lock.yml # Weekly `nix flake update` PR
.sops.yaml                      # sops-nix encryption rules
```

## Keeping Inputs Current

Dependabot has no Nix ecosystem — it cannot read `flake.nix` or `flake.lock`. So the
two halves are split:

| File | Covers |
|------|--------|
| `.github/workflows/update-flake-lock.yml` | `flake.lock`. Runs `nix flake update` every Monday 06:00 UTC (or on `workflow_dispatch`) and opens a PR via `peter-evans/create-pull-request`. It calls those two steps directly rather than using `DeterminateSystems/update-flake-lock`: that composite's latest release (v28) still pins four helper actions declaring `runs.using: node20`, which raised a Node 20 deprecation warning on every run with no way to configure it away. Driving it ourselves keeps every action on `node24` and removes four third-party dependencies from a workflow holding `contents: write`. Limited to `nixpkgs home-manager stylix sops-nix niri` — **`nixpkgs-libinput` is excluded on purpose**, since it is pinned to commit `68a8af93` for libinput 1.29.2 and moving it kills keyboard/touchpad enumeration on the P14s. `herdr` pins its release tag inside the input URL, so `nix flake update` cannot move it either; bump that tag by hand. |
| `.github/dependabot.yml` | The `github-actions` used by that workflow, weekly. Actions are pinned by commit SHA with a trailing `# vNN` comment (tags are mutable and thus a supply-chain risk); Dependabot bumps both. |

The workflow needs **Settings → Actions → General → "Allow GitHub Actions to create and
approve pull requests"** enabled, or the default `GITHUB_TOKEN` cannot open the PR.

A merged lockfile PR is not applied to any machine until you run `rebuild` locally —
review the diff, then rebuild, exactly as with a manual `update`.

## Flake Inputs

| Input | Purpose |
|-------|---------|
| [nixpkgs](https://github.com/NixOS/nixpkgs) (unstable) | System packages |
| [home-manager](https://github.com/nix-community/home-manager) | User-level config |
| [stylix](https://github.com/danth/stylix) | Consistent theming |
| [sops-nix](https://github.com/Mic92/sops-nix) | Secrets management |
| [niri-flake](https://github.com/sodiboo/niri-flake) | niri itself, pinned independently of the nixpkgs release cadence (exposes `pkgs.niri-stable` / `pkgs.niri-unstable`) |
| [herdr](https://github.com/ogulcancelik/herdr) | Agent multiplexer TUI, not in nixpkgs. Pinned to a release tag **inside the input URL**, so `nix flake update` cannot move it — bump the tag by hand |
| nixpkgs (pinned, `68a8af93`) | `nixpkgs-libinput`. Sources two packages the current unstable can no longer provide, both via overlays in `modules/niri.nix`: **libinput 1.29.2** (1.31 stops enumerating the P14s keyboard/touchpad) and **libdisplay-info 0.2.0** (nixpkgs replaced `libdisplay-info_0_2` with a throw alias in 2026-08; niri-flake still asserts exactly 0.2.0, and its `? libdisplay-info` fallback never fires because the alias is present rather than absent). Excluded from the automated lockfile updates — see [Keeping Inputs Current](#keeping-inputs-current) |

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
# Note: users.mutableUsers = false — the sops hash is the login password on
# every rebuild; manual `passwd` changes are reverted. Existing hosts need a
# key that can decrypt secrets.yaml (add new recipients + `sops updatekeys`).

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
| `Mod+Shift+D` | sys-doctor — evidence bundle + Claude Code diagnosis in a terminal |
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
| `Mod+Ctrl+V` | 📋 Clipboard history — rofi list of past selections, text or image (`clip-picker`) |
| `Mod+P` | 🎧 Headphone audio mode — stops EasyEffects and routes everything to the connected Bluetooth device |
| `Mod+Shift+P` | 🔊 Speaker audio mode — default sink → built-in speaker (p14s) or line-out desk speakers (darkstar); starts EasyEffects on p14s |
| `Mod+O` | 󰕾 Output picker — rofi list of every sink; sets the default **and** moves already-playing streams to it (`sink-picker`) |
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
| `netcheck [host]` | Split WiFi-link vs upstream-internet health check (signal, latency, packet loss) — tells at a glance whether a video stutter is local WiFi or the Starlink uplink |

## License

Feel free to use, modify, and share.
