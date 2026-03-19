{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # ── Boot ──────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.consoleLogLevel = 0;
  boot.kernelParams = [ "quiet" "udev.log_level=3" ];

  # ── Networking ────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # ── Tailscale ─────────────────────────────────────────
  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # ── Locale ────────────────────────────────────────────
  time.timeZone = "America/Boise";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Users ─────────────────────────────────────────────
  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "video"
      "audio"
    ];
    shell = pkgs.fish;
  };

  # ── Nix settings ──────────────────────────────────────
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # ── System packages ───────────────────────────────────
  environment.systemPackages = with pkgs; [
    git
    curl
    wget
    unzip
    busybox
    alsa-utils
  ];
  # ── Shell ─────────────────────────────────────────────
  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;

  # ── Security ──────────────────────────────────────────
  security.polkit.enable = true;
  security.rtkit.enable = true;

  # ── Pipewire (audio) ──────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # ── Network browsing (Nautilus) ───────────────────────
  services.gvfs.enable = true;
  services.samba = {
    enable = true;
    openFirewall = true;
    settings.global = {
      # performance
      "socket options" = "TCP_NODELAY IPTOS_LOWDELAY SO_RCVBUF=131072 SO_SNDBUF=131072";
      "use sendfile" = "yes";
      "min receivefile size" = "16384";
      "aio read size" = "16384";
      "aio write size" = "16384";
      # use SMB3 only (faster, secure)
      "server min protocol" = "SMB3";
      "client min protocol" = "SMB3";
    };
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  # ── Printing ─────────────────────────────────────
  services.printing.enable = true;

  # ── Firmware ──────────────────────────────────────────
  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  # ── nix-ld (for non-nix binaries) ────────────────────
  programs.nix-ld.enable = true;

  # ── Stylix (global theming — gruvbox) ─────────────────
  stylix = {
    enable = true;
    image = ./wallpaper.png;
    polarity = "dark";
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

    fonts = {
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.fira-code;
        name = "FiraCode Nerd Font Mono";
      };
      sizes = {
        applications = 10;
        desktop = 10;
        popups = 16;
        terminal = 11;
      };
    };

    cursor = {
      package = pkgs.phinger-cursors;
      name = "phinger-cursors-light";
      size = 18;
    };

    opacity = {
      terminal = 0.95;
      applications = 1.0;
    };

    # avoid conflicts
    targets.gnome.enable = false;
  };

  system.stateVersion = "24.11";
}
