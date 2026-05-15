{ config, pkgs, inputs, ... }:

{
  # niri-flake overlay exposes pkgs.niri-stable and pkgs.niri-unstable.
  # We pin to niri-stable, which is whichever release sodiboo currently
  # ships as stable. Switch to niri-unstable if a regression needs a fix
  # from main, or override `programs.niri.package` to a specific version.
  #
  # libinput overlay: nixpkgs unstable shipped libinput 1.31.1 around
  # 2026-05-13 and it stopped enumerating the internal keyboard / Elan
  # touchpad on this ThinkPad P14s Gen 6 AMD. Niri then runs but with no
  # input devices. Pin to 1.29.2 sourced from the older nixpkgs input.
  nixpkgs.overlays = [
    inputs.niri.overlays.niri
    (final: prev: {
      libinput = inputs.nixpkgs-libinput.legacyPackages.${prev.stdenv.hostPlatform.system}.libinput;
    })
  ];

  # niri WM — system-level settings
  programs.niri.enable = true;
  programs.niri.package = pkgs.niri-stable;

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
