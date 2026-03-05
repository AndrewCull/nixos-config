{ config, pkgs, lib, ... }:

let
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(printf " Lock\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown\n󰗽 Logout" | rofi -dmenu -p "Power")

    case "$choice" in
      *Lock*)     hyprlock ;;
      *Suspend*)  hyprlock & sleep 0.5 && systemctl suspend ;;
      *Reboot*)   systemctl reboot ;;
      *Shutdown*) systemctl poweroff ;;
      *Logout*)   niri msg action quit ;;
    esac
  '';

  keybinds-cheat = pkgs.writeShellScriptBin "keybinds-cheat" ''
    config="$HOME/.config/niri/config.kdl"
    section=""
    {
      while IFS= read -r line; do
        # Section headers from comments
        if [[ "$line" =~ ^[[:space:]]*//\ ──\ (.+)\ ── ]]; then
          section="''${BASH_REMATCH[1]}"
          continue
        fi
        # Skip comments, empty lines, non-bind lines
        [[ "$line" =~ ^[[:space:]]*// ]] && continue
        [[ -z "''${line// }" ]] && continue
        # Match keybindings: Key { action; }
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z0-9+_]+)[[:space:]]*(allow-when-locked=true)?[[:space:]]*\{[[:space:]]*(.+)\;[[:space:]]*\} ]]; then
          key="''${BASH_REMATCH[1]}"
          action="''${BASH_REMATCH[3]}"
          # Clean up action: remove spawn quotes, just show the command
          action=$(echo "$action" | sed 's/spawn "//;s/" "/\ /g;s/"//g')
          if [ -n "$section" ]; then
            printf "%-28s  %s\n" "$key" "$action"
          fi
        fi
      done < "$config"
    } | rofi -dmenu -p "Keybindings" -i -no-custom -theme-str 'window {width: 50%;}'
  '';

  wallpaper-launch = pkgs.writeShellScriptBin "wallpaper-launch" ''
    state="$HOME/.config/current-wallpaper"
    fallback="$HOME/wallpaper.jpg"
    wp=$(cat "$state" 2>/dev/null)
    [ ! -f "$wp" ] && wp="$fallback"
    [ -f "$wp" ] && exec swaybg -m fill -i "$wp"
  '';

  wallpaper-pick = pkgs.writeShellScriptBin "wallpaper-pick" ''
    dir="$HOME/wallpapers"
    state="$HOME/.config/current-wallpaper"
    mkdir -p "$dir"

    files=$(find "$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | sort)
    [ -z "$files" ] && notify-send "No wallpapers" "Add images to ~/wallpapers/" && exit 1

    selected=$(echo "$files" | sed "s|$dir/||" | rofi -dmenu -p "Wallpaper")
    [ -z "$selected" ] && exit 0

    echo "$dir/$selected" > "$state"
    pkill swaybg 2>/dev/null; sleep 0.1
    swaybg -m fill -i "$dir/$selected" &
    disown
  '';

  mic-mute-toggle = pkgs.writeShellScriptBin "mic-mute-toggle" ''
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    ${pkgs.alsa-utils}/bin/amixer -c1 set Capture toggle
  '';

  wallpaper-next = pkgs.writeShellScriptBin "wallpaper-next" ''
    dir="$HOME/wallpapers"
    state="$HOME/.config/current-wallpaper"
    mkdir -p "$dir"

    mapfile -t files < <(find "$dir" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | sort)
    [ ''${#files[@]} -eq 0 ] && exit 1

    current=$(cat "$state" 2>/dev/null || echo "")
    next_idx=0
    for i in "''${!files[@]}"; do
      if [ "''${files[$i]}" = "$current" ]; then
        next_idx=$(( (i + 1) % ''${#files[@]} ))
        break
      fi
    done

    echo "''${files[$next_idx]}" > "$state"
    pkill swaybg 2>/dev/null; sleep 0.1
    swaybg -m fill -i "''${files[$next_idx]}" &
    disown
  '';
in
{
  xdg.configFile."niri/config.kdl".source = ../confs/niri/config.kdl;
  xdg.configFile."hypr/hyprlock.conf".source = ../confs/hyprlock.conf;

  home.packages = with pkgs; [
    # bar
    waybar

    # launcher
    rofi

    # notifications
    mako

    # screen lock
    hyprlock

    # idle management
    swayidle

    # wallpaper
    swaybg

    # screenshot
    grim
    slurp

    # clipboard
    wl-clipboard
    cliphist

    # audio
    pamixer

    # misc wayland
    wl-screenrec
    bluetuith
    wlr-randr
    xwayland-satellite

    # scripts
    power-menu
    keybinds-cheat
    wallpaper-launch
    wallpaper-pick
    wallpaper-next
    mic-mute-toggle
  ];

  # ── Waybar ──────────────────────────────────────────
  programs.waybar = {
    enable = true;
    style = ''
      #workspaces button.active {
        border-radius: 0;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        modules-left = [ "niri/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "cpu"
          "memory"
          "network"
          "bluetooth"
          "pulseaudio"
          "battery"
        ];

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

        network = {
          format-wifi = "󰤨 {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰤭";
          tooltip-format = "{ifname}: {ipaddr}";
          on-click = "ghostty -e nmtui";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-icons = { default = [ "󰕿" "󰖀" "󰕾" ]; };
          format-muted = "󰝟";
        };

        cpu = {
          format = " {usage}%";
          interval = 5;
          on-click = "ghostty -e btop";
        };

        memory = {
          format = "󰍛 {percentage}%";
          interval = 5;
          tooltip-format = "{used:0.1f}G / {total:0.1f}G";
          on-click = "ghostty -e btop";
        };

        bluetooth = {
          format = "󰂯";
          format-connected = "󰂱 {num_connections}";
          format-disabled = "";
          tooltip-format-connected = "{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias} {device_battery_percentage}%";
          on-click = "ghostty -e bluetuith";
        };
      };
    };
  };

  # ── Rofi launcher ───────────────────────────────────
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    terminal = "ghostty";
    extraConfig = {
      show-icons = true;
      display-drun = "";
      display-run = "";
      display-window = "";
    };
  };

  # ── Mako notifications ──────────────────────────────
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-size = 1;
      border-radius = 0;
      font = lib.mkForce "Inter 10";
    };
  };

  # ── Swayidle ────────────────────────────────────────
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.hyprlock}/bin/hyprlock";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events = {
      before-sleep = "${pkgs.hyprlock}/bin/hyprlock";
    };
  };
}
