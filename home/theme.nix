{ config, pkgs, ... }:

{
  # GTK dark mode
  gtk = {
    enable = true;
    gtk3.extraConfig = { gtk-application-prefer-dark-theme = 1; };
    gtk4.extraConfig = { gtk-application-prefer-dark-theme = 1; };
  };

  # dconf dark mode for apps that check
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    libnotify
    glib
    brightnessctl
    networkmanagerapplet
    pwvucontrol   # pipewire audio control
  ];
}
