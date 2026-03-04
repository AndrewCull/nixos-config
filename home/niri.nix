{ config, pkgs, inputs, lib, ... }:

let
  power-menu = pkgs.writeShellScriptBin "power-menu" ''
    choice=$(printf " Lock\n󰤄 Suspend\n󰜉 Reboot\n󰐥 Shutdown\n󰗽 Logout" | fuzzel --dmenu --width 20 --lines 5 --prompt "Power: ")

    case "$choice" in
      *Lock*)     swaylock -f ;;
      *Suspend*)  swaylock -f && systemctl suspend ;;
      *Reboot*)   systemctl reboot ;;
      *Shutdown*) systemctl poweroff ;;
      *Logout*)   niri msg action quit ;;
    esac
  '';
in
{
  imports = [
    inputs.niri-flake.homeModules.niri
  ];

  programs.niri = {
    enable = true;

    # raw config.kdl — avoids niri-flake action name mismatches
    config = lib.mkForce (builtins.readFile ../confs/niri/config.kdl);
  };

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

    # misc wayland
    wl-screenrec
    wlr-randr

    # power menu
    power-menu
  ];

  # ── Waybar ──────────────────────────────────────────
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
  };

  # ── Fuzzel launcher ─────────────────────────────────
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        layer = "overlay";
        width = 60;
      };
      border.width = 1;
    };
  };

  # ── Mako notifications ──────────────────────────────
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;
      border-size = 1;
      border-radius = 0;
    };
  };

  # ── Swayidle ────────────────────────────────────────
  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
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
