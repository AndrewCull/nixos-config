{ config, pkgs, inputs, ... }:

{
  # niri WM — system-level settings
  programs.niri.enable = true;

  # Display manager
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd niri-session";
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
  security.pam.services.greetd.fprintAuth = false;

  # Hyprlock PAM — needed for screen lock authentication.
  # fprintAuth disabled: when the lid is closed or finger isn't on the reader,
  # fprintd retries and times out for ~10s before hyprlock will accept the
  # password, causing failed unlock attempts and long post-password delays.
  security.pam.services.hyprlock.fprintAuth = false;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
