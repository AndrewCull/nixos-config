{ config, pkgs, ... }:

{
  # ── Niri config ───────────────────────────────────────
  # niri-flake provides home-manager options
  # Full config reference: https://github.com/YaLTeR/niri/wiki/Configuration-Overview

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
    swaybg

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

  # ── Waybar ────────────────────────────────────────────
  programs.waybar = {
    enable = true;
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
    # CSS styling handled by stylix, override here if needed
  };

  # ── Fuzzel launcher ───────────────────────────────────
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        layer = "overlay";
        width = 40;
        font = "JetBrains Mono:size=11";
      };
      border = {
        width = 1;
      };
    };
  };

  # ── Mako notifications ───────────────────────────────
  services.mako = {
    enable = true;
    defaultTimeout = 5000;
    borderSize = 1;
    borderRadius = 0; # no rounded corners
    padding = "10";
    margin = "10";
    font = "Inter 10";
  };

  # ── Swayidle ──────────────────────────────────────────
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
      }
    ];
    events = [
      {
        event = "before-sleep";
        command = "${pkgs.swaylock-effects}/bin/swaylock -f";
      }
    ];
  };
}
