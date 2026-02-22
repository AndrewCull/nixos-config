{ config, pkgs, inputs, ... }:

{
  # ── Niri compositor ───────────────────────────────────
  programs.niri.enable = true;

  # ── Supporting Wayland services ───────────────────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # XDG portal for screen sharing, file dialogs, etc.
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # ── Wayland environment ───────────────────────────────
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # chromium/electron wayland
    MOZ_ENABLE_WAYLAND = "1";
  };

  # ── Fonts ─────────────────────────────────────────────
  fonts = {
    packages = with pkgs; [
      inter
      jetbrains-mono
      nerd-fonts.jetbrains-mono
      noto-fonts
      noto-fonts-emoji
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
      monospace = [ "JetBrains Mono" ];
    };
  };
}
