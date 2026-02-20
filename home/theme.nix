{ config, pkgs, ... }:

{
  # ── GTK ───────────────────────────────────────────────
  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = "adw-gtk3-dark";
    };
    iconTheme = {
      package = pkgs.colloid-icon-theme.override {
        schemeVariants = [ "default" ];
        colorVariants = [ "dark" ];
      };
      name = "Colloid-dark";
    };
  };

  # ── QT (match GTK look) ──────────────────────────────
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # force dark mode for apps that check
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}
