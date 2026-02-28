{ config, pkgs, inputs, ... }:

{
  programs.noctalia-shell = {
    enable = true;
    package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;

    systemd.enable = true;

    settings = {
      bar.density = "compact";
      bar.position = "top";
      general.radiusRatio = 0.0;
    };

    colors = {
      # Material 3 scheme mapped from Stylix base16 palette
      mSurface = "#121218";           # base00
      mSurfaceVariant = "#1a1a22";    # base01
      mSurfaceContainer = "#1a1a22";  # base01
      mOnSurface = "#c8c8d0";         # base05
      mOnSurfaceVariant = "#6a6a80";  # base04
      mOutline = "#2a2a35";           # base02
      mOutlineVariant = "#45455a";    # base03
      mPrimary = "#60b8b8";           # base0C — teal accent
      mOnPrimary = "#121218";         # base00
      mPrimaryContainer = "#2a2a35";  # base02
      mOnPrimaryContainer = "#c8c8d0"; # base05
      mSecondary = "#6090c8";         # base0D — blue
      mOnSecondary = "#121218";       # base00
      mSecondaryContainer = "#2a2a35"; # base02
      mOnSecondaryContainer = "#c8c8d0"; # base05
      mTertiary = "#9070c8";          # base0E — purple
      mOnTertiary = "#121218";        # base00
      mTertiaryContainer = "#2a2a35"; # base02
      mOnTertiaryContainer = "#c8c8d0"; # base05
      mError = "#c87070";             # base08
      mOnError = "#121218";           # base00
      mErrorContainer = "#2a2a35";    # base02
      mOnErrorContainer = "#c87070";  # base08
      mInverseSurface = "#c8c8d0";    # base05
      mOnInverseSurface = "#121218";  # base00
      mInversePrimary = "#60b8b8";    # base0C
      mShadow = "#000000";
      mScrim = "#000000";
    };

    plugins = [
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
