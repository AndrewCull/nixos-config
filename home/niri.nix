{ config, pkgs, lib, ... }:

let
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
      { command = [ "sh" "-c" "sleep 0.5 && swww img /home/andrew/wallpaper.jpg" ]; }
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
      "Mod+Q".action = close-window;
      "Mod+Shift+E".action = quit;

      # ── Focus ───────────────────────────────────
      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;

      # ── Move ────────────────────────────────────
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;

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
    };
  };

  # ── Waybar ────────────────────────────────────────────
  programs.waybar = {
    enable = true;
    style = ''
      * {
        font-family: monospace;
        font-size: 13px;
        border: none;
        border-radius: 0;
        min-height: 0;
      }
      window#waybar {
        background: #1a1a24;
        color: #c0c0d0;
      }
      #workspaces button {
        padding: 0 6px;
        color: #606070;
        border-bottom: 2px solid transparent;
        border-radius: 0;
      }
      #workspaces button.active {
        color: #60b8b8;
        border-bottom: 2px solid #60b8b8;
      }
      #clock, #battery, #network, #pulseaudio, #bluetooth {
        padding: 0 8px;
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
        };
      };
    };
  };

  # ── Fuzzel launcher ───────────────────────────────────
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        layer = "overlay";
        width = 60;
      };
      border = {
        width = 1;
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
