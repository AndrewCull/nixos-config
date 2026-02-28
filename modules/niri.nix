{ config, pkgs, inputs, ... }:

{
  imports = [
    inputs.noctalia.nixosModules.default
  ];

  # ── Niri compositor ───────────────────────────────────
  programs.niri.enable = true;

  # ── Noctalia shell ──────────────────────────────────
  services.noctalia-shell.enable = true;

  # ── Supporting Wayland services ───────────────────────
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session --sessions ${config.services.displayManager.sessionData.desktops}/share";
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
      noto-fonts-color-emoji
    ];
    fontconfig.defaultFonts = {
      sansSerif = [ "Inter" ];
      monospace = [ "JetBrains Mono" ];
    };
  };
}
