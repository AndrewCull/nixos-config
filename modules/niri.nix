{ config, pkgs, inputs, ... }:

{
  # niri WM — system-level settings
  programs.niri.enable = true;

  # Display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
        user = "greeter";
      };
    };
  };

  # XDG portal for screen sharing, file dialogs
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
  };

  # GNOME Keyring — auto-unlock on login
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.greetd.fprintAuth = true;

  # Hyprlock PAM — needed for screen lock authentication
  security.pam.services.hyprlock = {};

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
