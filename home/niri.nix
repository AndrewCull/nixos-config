{ config, pkgs, lib, ... }:

let
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(printf " Lock\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown\n󰗽 Logout" | rofi -dmenu -p "Power")

    case "$choice" in
      *Lock*)     hyprlock ;;
      *Suspend*)  hyprlock & sleep 1 && systemctl suspend ;;
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

  # Build a waybar style file that @imports the stylix/home-manager-generated
  # style (which must stay the FIRST statement — GTK CSS rejects @import after
  # any rule) and appends a single window#waybar background override sourced
  # from the wallpaper's dominant color.
  wallpaper-colorize = pkgs.writeShellScriptBin "wallpaper-colorize" ''
    wp="''${1:-$(cat "$HOME/.config/current-wallpaper" 2>/dev/null)}"
    out="$HOME/.cache/waybar/style.css"
    base="$HOME/.config/waybar/style.css"
    mkdir -p "$(dirname "$out")"

    {
      printf '@import "%s";\n' "$base"
      if [ -f "$wp" ]; then
        hex=$(${pkgs.imagemagick}/bin/magick "$wp" -resize 200x200 -colors 5 -depth 8 -format "%c" histogram:info: \
          | sort -rn \
          | ${pkgs.gawk}/bin/awk 'NR==1 { for (i=1;i<=NF;i++) if ($i ~ /^#[0-9A-Fa-f]{6}/) { print substr($i,1,7); exit } }')
        if [ -n "$hex" ]; then
          r=$((16#''${hex:1:2}))
          g=$((16#''${hex:3:2}))
          b=$((16#''${hex:5:2}))
          max=$r
          [ $g -gt $max ] && max=$g
          [ $b -gt $max ] && max=$b
          if [ "$max" -gt 80 ]; then
            r=$(( r * 80 / max ))
            g=$(( g * 80 / max ))
            b=$(( b * 80 / max ))
          fi
          printf 'window#waybar { background-color: rgba(%d, %d, %d, 0.92); }\n' "$r" "$g" "$b"
        fi
      fi
    } > "$out"

    ${pkgs.procps}/bin/pkill -SIGUSR2 waybar 2>/dev/null || true
  '';

  waybar-launcher = pkgs.writeShellScriptBin "waybar-launcher" ''
    # Seed the runtime style with the base @import so waybar can start even
    # before any wallpaper has been picked.
    out="$HOME/.cache/waybar/style.css"
    mkdir -p "$(dirname "$out")"
    [ -s "$out" ] || printf '@import "%s";\n' "$HOME/.config/waybar/style.css" > "$out"
    exec ${pkgs.waybar}/bin/waybar -s "$out"
  '';

  wallpaper-launch = pkgs.writeShellScriptBin "wallpaper-launch" ''
    state="$HOME/.config/current-wallpaper"
    fallback="$HOME/wallpaper.jpg"
    wp=$(cat "$state" 2>/dev/null)
    [ ! -f "$wp" ] && wp="$fallback"
    if [ -f "$wp" ]; then
      ${wallpaper-colorize}/bin/wallpaper-colorize "$wp" || true
      exec swaybg -m fill -i "$wp"
    fi
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
    ${wallpaper-colorize}/bin/wallpaper-colorize "$dir/$selected" || true
  '';

  mic-mute-toggle = pkgs.writeShellScriptBin "mic-mute-toggle" ''
    # Toggle default source first, then read its new state
    ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
    muted=$(${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | ${pkgs.gnugrep}/bin/grep -c MUTED)

    # Sync all other sources to match
    ${pkgs.wireplumber}/bin/wpctl status | ${pkgs.gawk}/bin/awk '
      /Sources:/ { s=1; next }
      s && /Filters:|Streams:|^$/ { exit }
      s { match($0, /[0-9]+\./); if (RSTART) print substr($0, RSTART, RLENGTH-1) }
    ' | while read -r id; do
      ${pkgs.wireplumber}/bin/wpctl set-mute "$id" "$muted"
    done

    # Sync LED with mute state
    LED=/sys/devices/platform/thinkpad_acpi/leds/platform::micmute/brightness
    [ -w "$LED" ] && echo "$muted" > "$LED"
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
    ${wallpaper-colorize}/bin/wallpaper-colorize "''${files[$next_idx]}" || true
  '';
in
{
  xdg.configFile."niri/config.kdl".source = ../confs/niri/config.kdl;
  xdg.configFile."hypr/hyprlock.conf".source = ../confs/hyprlock.conf;

  # Seed the runtime waybar style that niri launches with, so waybar can come
  # up before any wallpaper has been picked. waybar-launcher re-seeds it at
  # runtime too; this just covers the first boot after activation.
  home.activation.waybarRuntimeStyle = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p $HOME/.cache/waybar
    if [ ! -s $HOME/.cache/waybar/style.css ]; then
      run sh -c 'printf ''\''@import "%s";\n''\'' "$HOME/.config/waybar/style.css" > "$HOME/.cache/waybar/style.css"'
    fi
  '';

  home.packages = with pkgs; [
    # bar
    waybar

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

    # polkit auth agent (GUI password prompts for fprintd enrol, etc.)
    hyprpolkitagent

    # scripts
    power-menu
    keybinds-cheat
    wallpaper-launch
    wallpaper-pick
    wallpaper-next
    wallpaper-colorize
    waybar-launcher
    mic-mute-toggle
  ];

  # ── Waybar ──────────────────────────────────────────
  programs.waybar = {
    enable = true;
    style = with config.lib.stylix.colors; ''
      * {
        font-size: 14px;
      }
      #workspaces button.active {
        border-radius: 0;
      }
      #custom-tailscale,
      #memory,
      #network,
      #bluetooth,
      #pulseaudio,
      #battery {
        margin: 0 4px;
      }
      #custom-launcher {
        font-size: 24px;
        margin: 3px 12px 3px 8px;
        padding: 0 10px;
        border: 1px solid #${base03};
        border-radius: 0;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        modules-left = [ "custom/launcher" "niri/workspaces" ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/tailscale"
          "memory"
          "network"
          "bluetooth"
          "pulseaudio"
          "battery"
        ];

        "custom/launcher" = {
          format = "󱄅";
          tooltip = false;
          on-click = "rofi -show drun";
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%a %b %d}";
          tooltip-format = "{:%Y-%m-%d %H:%M}";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "<span size='large'>󰂎</span>" "<span size='large'>󰁺</span>" "<span size='large'>󰁻</span>" "<span size='large'>󰁼</span>" "<span size='large'>󰁽</span>" "<span size='large'>󰁾</span>" "<span size='large'>󰁿</span>" "<span size='large'>󰂀</span>" "<span size='large'>󰂁</span>" "<span size='large'>󰂂</span>" "<span size='large'>󰁹</span>" ];
          format-charging = "<span size='large'>󰂄</span> {capacity}%";
        };

        network = {
          format-wifi = "<span size='large'>󰤨</span> {signalStrength}%";
          format-ethernet = "<span size='large'>󰈀</span>";
          format-disconnected = "<span size='large'>󰤭</span>";
          tooltip-format = "{ifname}: {ipaddr}";
          interval = 30;
          on-click = "ghostty -e nmtui";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-icons = { default = [ "<span size='large'>󰕿</span>" "<span size='large'>󰖀</span>" "<span size='large'>󰕾</span>" ]; };
          format-muted = "<span size='large'>󰝟</span>";
          on-click = "${pkgs.writeShellScript "rofi-sink-picker" ''
            set -eu
            PACTL=${pkgs.pulseaudio}/bin/pactl
            ROFI=${pkgs.rofi}/bin/rofi
            default=$($PACTL get-default-sink)
            mapfile -t lines < <($PACTL -f json list sinks | ${pkgs.jq}/bin/jq -r '.[] | "\(.name)\t\(.description)"')
            menu=""
            for l in "''${lines[@]}"; do
              name="''${l%%	*}"
              desc="''${l#*	}"
              prefix="  "
              [ "$name" = "$default" ] && prefix="● "
              menu+="$prefix$desc"$'\n'
            done
            chosen=$(printf '%s' "$menu" | $ROFI -dmenu -i -p "Output" -theme-str 'window { width: 30%; }')
            [ -z "$chosen" ] && exit 0
            chosen="''${chosen#* }"
            for l in "''${lines[@]}"; do
              name="''${l%%	*}"
              desc="''${l#*	}"
              if [ "$desc" = "$chosen" ]; then
                $PACTL set-default-sink "$name"
                $PACTL list short sink-inputs | while read -r id _; do
                  $PACTL move-sink-input "$id" "$name" || true
                done
                break
              fi
            done
          ''}";
          on-click-right = "${pkgs.pavucontrol}/bin/pavucontrol";
        };

        "custom/tailscale" = {
          format = "{}";
          interval = 10;
          exec = pkgs.writeShellScript "waybar-tailscale" ''
            S="large"
            status=$(${pkgs.tailscale}/bin/tailscale status --json 2>/dev/null)
            if [ $? -ne 0 ]; then
              echo "{\"text\": \"<span size='$S'>󰖂</span> ↓\", \"tooltip\": \"Tailscale: not running\", \"class\": \"disconnected\"}"
              exit 0
            fi
            backend=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.BackendState')
            if [ "$backend" != "Running" ]; then
              echo "{\"text\": \"<span size='$S'>󰖂</span> ↓\", \"tooltip\": \"Tailscale: $backend\", \"class\": \"disconnected\"}"
              exit 0
            fi
            exit_node=$(echo "$status" | ${pkgs.jq}/bin/jq -r '.ExitNodeStatus.ID // empty')
            if [ -n "$exit_node" ]; then
              exit_name=$(echo "$status" | ${pkgs.jq}/bin/jq -r --arg id "$exit_node" '.Peer[$id].HostName // "unknown"')
              echo "{\"text\": \"<span size='$S'>󱇱</span> ↑\", \"tooltip\": \"Tailscale: exit node $exit_name\", \"class\": \"exit-node\"}"
            else
              echo "{\"text\": \"<span size='$S'>󰖂</span> ↑\", \"tooltip\": \"Tailscale: connected\", \"class\": \"connected\"}"
            fi
          '';
          return-type = "json";
          on-click = "${pkgs.trayscale}/bin/trayscale";
        };

        memory = {
          format = "<span size='large'>󰍛</span> {percentage}%";
          interval = 5;
          tooltip-format = "{used:0.1f}G / {total:0.1f}G";
          on-click = "ghostty -e btop";
        };

        bluetooth = {
          format = "<span size='large'>󰂯</span>";
          format-connected = "<span size='large'>󰂱</span> {num_connections}";
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
    plugins = [ pkgs.rofi-calc ];
    terminal = "ghostty";
    theme = lib.mkForce "${pkgs.writeText "stylix-wide.rasi" (with config.lib.stylix.colors; ''
      * {
        bg:       #${base00};
        bg-alt:   #${base01};
        bg-sel:   #${base02};
        fg:       #${base05};
        fg-dim:   #${base04};
        accent:   #${base0D};
        urgent:   #${base08};
        border:   #${base02};

        background-color: transparent;
        text-color:       @fg;
        font:             "JetBrainsMono Nerd Font 12";
      }

      window {
        width:            55%;
        background-color: @bg;
        border:           1px;
        border-color:     @border;
        border-radius:    0;
        padding:          14px;
      }

      mainbox {
        children: [ inputbar, message, listview ];
        spacing:  12px;
      }

      inputbar {
        background-color: @bg-alt;
        border-radius:    0;
        padding:          10px 14px;
        spacing:          10px;
        children:         [ prompt, entry ];
      }

      prompt { text-color: @accent; }

      entry {
        placeholder:       "Search…";
        placeholder-color: @fg-dim;
      }

      message {
        background-color: @bg-alt;
        border-radius:    0;
        padding:          8px 12px;
      }

      textbox { text-color: @fg; }

      listview {
        columns:      2;
        lines:        8;
        spacing:      6px;
        cycle:        true;
        dynamic:      true;
        scrollbar:    false;
        fixed-height: true;
      }

      element {
        padding:       8px 10px;
        spacing:       10px;
        border-radius: 0;
      }

      element selected {
        background-color: @accent;
        text-color:       @bg;
      }

      element-icon {
        size:             22px;
        background-color: transparent;
      }

      element-text {
        text-color:       inherit;
        background-color: transparent;
        vertical-align:   0.5;
      }
    '')}";
    extraConfig = {
      modi = "drun,run,window,calc";
      show-icons = true;
      display-drun = "";
      display-run = "";
      display-window = "";
      display-calc = "";
      location = 1;   # north-west
      anchor = 1;     # north-west
      x-offset = 0;
      y-offset = 28;  # matches waybar height
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

  # ── Polkit auth agent ───────────────────────────────
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit authentication agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── Swayidle ────────────────────────────────────────
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 900;
        command = toString (pkgs.writeShellScript "lock-then-sleep-screen" ''
          ${pkgs.procps}/bin/pgrep -x hyprlock || ${pkgs.hyprlock}/bin/hyprlock &
          sleep 300
          if ${pkgs.procps}/bin/pgrep -x hyprlock > /dev/null; then
            ${pkgs.niri}/bin/niri msg action power-off-monitors
          fi
        '');
      }
    ];
    events = {
      before-sleep = "${pkgs.systemd}/bin/loginctl lock-session";
      lock = "${pkgs.procps}/bin/pgrep -x hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
    };
  };
}
