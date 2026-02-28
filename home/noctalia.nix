{ config, ... }:

{
  programs.noctalia-shell = {
    enable = true;

    systemd.enable = true;

    settings = {
      bar.density = "compact";
      bar.position = "top";
      general.radiusRatio = 0.0;
    };

    # colors are managed by Stylix (base16 → Material 3 mapping)

    plugins = let
      noctaliaPlugins = "https://github.com/noctalia-dev/noctalia-plugins";
      enablePlugin = name: {
        inherit name;
        value = { enabled = true; sourceUrl = noctaliaPlugins; };
      };
      pluginNames = [
        "clipper"
        "screenshot"
        "screen-recorder"
        "color-scheme-creator"
        "mini-docker"
        "todo"
        "pomodoro"
        "niri-overview-launcher"
        "tailscale"
        "network-manager-vpn"
        "weather-indicator"
        "world-clock"
        "polkit-agent"
        "privacy-indicator"
      ];
    in {
      sources = [
        {
          enabled = true;
          name = "Noctalia Plugins";
          url = noctaliaPlugins;
        }
      ];
      states = builtins.listToAttrs (map enablePlugin pluginNames);
      version = 2;
    };

    pluginSettings = {
      clipper = {
        maxItems = 100;
        showImages = true;
      };
      screenshot = {
        saveDirectory = "~/Pictures/Screenshots";
        copyToClipboard = true;
      };
      screen-recorder = {
        saveDirectory = "~/Videos/Recordings";
      };
      weather-indicator = {
        units = "imperial";
      };
    };
  };
}
