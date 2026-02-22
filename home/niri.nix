{ config, pkgs, lib, ... }:

let
  # ── Wallpapers from dharmx/walls ──────────────────────
  wallpapers = pkgs.fetchFromGitHub {
    owner = "dharmx";
    repo = "walls";
    rev = "6bf4d733ebf2b484a37c17d742eb47e5139e6a14";
    hash = "sha256-Ldvnevfspacy1Tavrxg3/LCd99GdwkdA+0yLxQvWXHw=";
    sparseCheckout = [
      "nord"
      "natura"
      "abstract"
      "minimal"
      "industrial"
    ];
  };

  wallpaper-daemon = pkgs.writeShellScript "wallpaper-daemon" ''
    set -euo pipefail

    WALLS="${wallpapers}"
    FOLDERS="nord natura abstract minimal industrial"

    # Collect all wallpaper paths
    declare -A WS_WALLPAPER
    ALL_WALLS=()
    for f in $FOLDERS; do
      for img in "$WALLS/$f"/*; do
        [ -f "$img" ] && ALL_WALLS+=("$img")
      done
    done

    if [ ''${#ALL_WALLS[@]} -eq 0 ]; then
      echo "wallpaper-daemon: no wallpapers found" >&2
      exit 1
    fi

    # Assign a random wallpaper to each workspace index 1-5
    for ws in 1 2 3 4 5; do
      idx=$(( RANDOM % ''${#ALL_WALLS[@]} ))
      WS_WALLPAPER[$ws]="''${ALL_WALLS[$idx]}"
    done

    # Build a map from niri workspace ID -> idx (1-based) using WorkspacesChanged
    declare -A ID_TO_IDX

    update_id_map() {
      local json="$1"
      # Parse the workspaces array and build id->idx mapping
      eval "$(echo "$json" | ${pkgs.jq}/bin/jq -r '
        .WorkspacesChanged.workspaces[]
        | "ID_TO_IDX[\(.id)]=\(.idx)"
      ' 2>/dev/null)" || true
    }

    # Set initial wallpaper for workspace 1
    ${pkgs.swww}/bin/swww img "''${WS_WALLPAPER[1]}" --transition-type fade --transition-duration 0.7

    CURRENT_IDX=1

    # Listen to niri event stream (process substitution to keep vars in main shell)
    while read -r line; do
      # Update workspace ID map when workspace config changes
      if echo "$line" | ${pkgs.jq}/bin/jq -e '.WorkspacesChanged' >/dev/null 2>&1; then
        update_id_map "$line"
      fi

      # Handle workspace activation
      ws_id=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.WorkspaceActivated.id // empty' 2>/dev/null)
      focused=$(echo "$line" | ${pkgs.jq}/bin/jq -r '.WorkspaceActivated.focused // empty' 2>/dev/null)

      if [ -n "$ws_id" ] && [ "$focused" = "true" ]; then
        ws_idx="''${ID_TO_IDX[$ws_id]:-}"
        if [ -n "$ws_idx" ] && [ "$ws_idx" -ge 1 ] && [ "$ws_idx" -le 5 ] && [ "$ws_idx" != "$CURRENT_IDX" ]; then
          target="''${WS_WALLPAPER[$ws_idx]}"
          if [ -n "$target" ]; then
            ${pkgs.swww}/bin/swww img "$target" --transition-type fade --transition-duration 0.7
            CURRENT_IDX="$ws_idx"
          fi
        fi
      fi
    done < <(niri msg event-stream)
  '';

  power-menu = pkgs.writeShellScript "power-menu" ''
    set -euo pipefail

    FUZZEL="${pkgs.fuzzel}/bin/fuzzel"
    SWAYLOCK="${pkgs.swaylock-effects}/bin/swaylock"

    show_power_profiles() {
      current=$(powerprofilesctl get)
      choice=$(printf "performance\nbalanced\npower-saver" \
        | $FUZZEL -d -p "Profile [$current] > ")
      [ -n "$choice" ] && powerprofilesctl set "$choice"
    }

    choice=$(printf \
      "Lock\nSuspend\nPower Profile\nLogout\nReboot\nShutdown" \
      | $FUZZEL -d -p "Power > ")

    case "$choice" in
      Lock)          $SWAYLOCK -f --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2 ;;
      Suspend)       systemctl suspend ;;
      "Power Profile") show_power_profiles ;;
      Logout)        niri msg action quit --skip-confirmation ;;
      Reboot)        systemctl reboot ;;
      Shutdown)      systemctl poweroff ;;
    esac
  '';

  inherit (config.lib.niri.actions)
    spawn
    close-window
    quit
    focus-column-left
    focus-column-right
    focus-window-down
    focus-window-up
    move-column-left
    move-column-right
    move-window-down
    move-window-up
    move-column-to-monitor-left
    move-column-to-monitor-right
    focus-monitor-left
    focus-monitor-right
    consume-window-into-column
    expel-window-from-column
    maximize-column
    fullscreen-window
    power-off-monitors
    focus-workspace-down
    focus-workspace-up
    focus-workspace-previous
    toggle-window-floating
    ;
in
{
  # ── Packages ─────────────────────────────────────────
  home.packages = with pkgs; [
    # bar
    waybar

    # launcher
    fuzzel

    # notifications
    mako

    # screen lock
    swaylock-effects

    # idle management
    swayidle

    # wallpaper
    swww

    # screenshot
    grim
    slurp

    # clipboard
    wl-clipboard
    cliphist

    # brightness/volume
    brightnessctl
    pamixer

    # file manager (tui)
    yazi

    # network/bluetooth TUIs
    impala       # wifi manager
    bluetui      # bluetooth manager

    # misc wayland utils
    wl-screenrec # screen recording
    wlr-randr    # display config
  ];

  # ── Niri settings ────────────────────────────────────
  programs.niri.settings = {

    spawn-at-startup = [
      { command = [ "waybar" ]; }
      { command = [ "mako" ]; }
      { command = [ "swww-daemon" ]; }
      { command = [ "sh" "-c" "sleep 0.5 && ${wallpaper-daemon}" ]; }
      { command = [ "sh" "-c" "wl-paste --watch cliphist store" ]; }
    ];

    input = {
      keyboard.xkb = {};
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    layout = {
      gaps = 0;
      focus-ring.enable = false;
      border = {
        enable = true;
        width = 2;
        active.color = "#60b8b8";
        inactive.color = "#2a2a35";
      };
      default-column-width.proportion = 0.5;
      center-focused-column = "never";
    };

    cursor = {
      theme = "Bibata-Modern-Classic";
      size = 22;
    };

    screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

    prefer-no-csd = true;

    window-rules = [
      {
        geometry-corner-radius = let r = 0.0; in {
          bottom-left = r;
          bottom-right = r;
          top-left = r;
          top-right = r;
        };
        clip-to-geometry = true;
      }
    ];

    binds = {
      # ── Launch ──────────────────────────────────
      "Mod+Return".action = spawn "ghostty";
      "Mod+T".action = spawn "ghostty";
      "Mod+D".action = spawn "fuzzel";
      "Mod+Space".action = spawn "fuzzel";
      "Mod+Q".action = close-window;
      "Mod+Shift+E".action = quit;

      # ── Focus ───────────────────────────────────
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;

      # ── Move ────────────────────────────────────
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;

      # ── Workspaces ─────────────────────────────
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Tab".action = focus-workspace-previous;

      # ── Sizing / layout ─────────────────────────
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+Minus".action.set-column-width = "-10%";
      "Mod+Equal".action.set-column-width = "+10%";
      "Mod+V".action = toggle-window-floating;
      "Mod+BracketLeft".action = consume-window-into-column;
      "Mod+BracketRight".action = expel-window-from-column;

      # ── Screenshot ─────────────────────────────
      "Mod+Shift+S".action = spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy";
      "Print".action.screenshot = [];

      # ── Monitor focus & move ──────────────────
      "Mod+Comma".action = focus-monitor-left;
      "Mod+Period".action = focus-monitor-right;
      "Mod+Shift+Comma".action = move-column-to-monitor-left;
      "Mod+Shift+Period".action = move-column-to-monitor-right;

      # ── Clipboard ─────────────────────────────
      "Mod+Shift+C".action = spawn "sh" "-c" "cliphist list | fuzzel -d | cliphist decode | wl-copy";

      # ── Scroll workspaces ──────────────────────
      "Mod+WheelScrollDown".action = focus-workspace-down;
      "Mod+WheelScrollUp".action = focus-workspace-up;

      # ── Media keys ─────────────────────────────
      "XF86AudioRaiseVolume".action = spawn "pamixer" "-i" "5";
      "XF86AudioLowerVolume".action = spawn "pamixer" "-d" "5";
      "XF86AudioMute".action = spawn "pamixer" "-t";
      "XF86MonBrightnessUp".action = spawn "brightnessctl" "set" "+5%";
      "XF86MonBrightnessDown".action = spawn "brightnessctl" "set" "5%-";

      # ── Power ───────────────────────────────────
      "Mod+Shift+P".action = power-off-monitors;
      "XF86PowerOff".action = spawn "sh" "-c" "${power-menu}";
      "Mod+Escape".action = spawn "sh" "-c" "${power-menu}";
    };
  };

  # ── Waybar ────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: monospace;
        font-size: 15px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
      window#waybar {
        background: #1a1a24;
        color: #c0c0d0;
      }
      #custom-launcher {
        font-size: 18px;
        padding: 0 12px 0 10px;
        color: #60b8b8;
      }
      #custom-launcher:hover {
        color: #80d8d8;
      }
      #workspaces button {
        padding: 0 8px;
        color: #606070;
        font-size: 14px;
        border-bottom: 2px solid transparent;
        border-radius: 0;
      }
      #workspaces button.active {
        color: #60b8b8;
        border-bottom: 2px solid #60b8b8;
      }
      #clock {
        font-size: 15px;
        padding: 0 10px;
      }
      #battery, #network, #pulseaudio, #bluetooth, #custom-tailscale {
        font-size: 16px;
        padding: 0 10px;
      }
      #custom-tailscale.connected {
        color: #60b8b8;
      }
      #custom-tailscale.disconnected {
        color: #606070;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 32;
        modules-left = [ "custom/launcher" "niri/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/tailscale"
          "network"
          "bluetooth"
          "pulseaudio"
          "battery"
        ];

        "custom/launcher" = {
          format = "  ";
          on-click = "fuzzel";
          tooltip = false;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%a %b %d}";
          tooltip-format = "{:%Y-%m-%d %H:%M}";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format-charging = "󰂄 {capacity}%";
        };

        "custom/tailscale" = {
          exec = pkgs.writeShellScript "waybar-tailscale" ''
            if ! tailscale status >/dev/null 2>&1; then
              echo '{"text": "󰖂", "class": "disconnected", "tooltip": "Tailscale: stopped"}'
            else
              ip=$(tailscale ip -4 2>/dev/null || echo "no ip")
              hostname=$(tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.Self.DNSName // empty' | sed 's/\.$//')
              echo "{\"text\": \"󰖂\", \"class\": \"connected\", \"tooltip\": \"Tailscale: $hostname\\n$ip\"}"
            fi
          '';
          return-type = "json";
          interval = 10;
          on-click = pkgs.writeShellScript "tailscale-toggle" ''
            if tailscale status >/dev/null 2>&1; then
              sudo tailscale down
            else
              sudo tailscale up
            fi
          '';
        };

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}";
          on-click = "ghostty -e impala";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-icons.default = [ "󰕿" "󰖀" "󰕾" ];
          format-muted = "󰝟";
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱";
          format-disabled = "";
          on-click = "rfkill unblock bluetooth; ghostty -e bluetui";
        };
      };
    };
  };

  # ── Fuzzel launcher ───────────────────────────────────
  # Colors and fonts are managed by Stylix
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        layer = "overlay";
        width = 50;
        lines = 12;
        horizontal-pad = 20;
        vertical-pad = 16;
        inner-pad = 8;
        line-height = 28;
        letter-spacing = 0;
        prompt = "\"> \"";
      };
      border = {
        width = 2;
        radius = 0;
      };
    };
  };

  # ── Mako notifications ────────────────────────────────
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-size = 1;
      border-radius = 0;
    };
  };

  # ── Swayidle ──────────────────────────────────────────
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 240;
        command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10%";
        resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
      }
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock -f --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock-effects}/bin/swaylock -f --clock --effect-blur 7x5 --effect-vignette 0.5:0.5 --fade-in 0.2";
    };
  };
}
