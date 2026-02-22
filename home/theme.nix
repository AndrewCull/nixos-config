{ config, pkgs, lib, ... }:

{
  # Stylix handles GTK theme, QT theme, cursor, and fonts.
  # We only need overrides it doesn't cover.

  # ── Icon theme (stylix doesn't set this) ─────────────
  gtk.iconTheme = {
    package = pkgs.colloid-icon-theme.override {
      schemeVariants = [ "default" ];
      colorVariants = [ "teal" ];
    };
    name = "Colloid-teal-dark";
  };

  # ── Force dark mode for apps that check dconf ────────
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
