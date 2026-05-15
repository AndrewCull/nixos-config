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

  # NXP NCI NFC chip generates a runaway i2c interrupt storm (IRQ pegs one
  # core ~15%, fans spin up, niri startup stalled ~47s during DRM init).
  # Unused on this machine — blacklist the whole NFC stack.
  boot.blacklistedKernelModules = [ "nxp_nci_i2c" "nxp_nci" "nci" "nfc" ];

  # ── Networking ────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 8081 ];

  # ── Tailscale ─────────────────────────────────────────
  # useRoutingFeatures = "client" enables proper exit-node usage
  # (Mullvad add-on or self-hosted exit nodes) — handles routing/MTU.
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };
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
      "i2c"
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
  services.gnome.localsearch.enable = true;
  services.gnome.tinysparql.enable = true;
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
    openFirewall = true;   # allow mDNS through the firewall (UDP 5353)
    publish = {
      enable = true;
      userServices = true;
    };
  };

  # ── Printing ─────────────────────────────────────
  services.printing = {
    enable = true;
    browsed.enable = true;
  };

  # ── Firmware ──────────────────────────────────────────
  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  # ── USB quirks ────────────────────────────────────────
  # BenQ monitor's Realtek hub mis-enumerates under USB-C + PD load and
  # the resulting bus turbulence resets the MediaTek BT radio, dropping
  # the HHKB + mouse. Pin autosuspend off on both so BT survives the storm.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0bda", ATTR{idProduct}=="5420", TEST=="power/control", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="0e8d", ATTR{idProduct}=="e025", TEST=="power/control", ATTR{power/control}="on"
  '';

  # ── nix-ld (for non-nix binaries) ────────────────────
  programs.nix-ld.enable = true;

  # ── AppImage support ─────────────────────────────────
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # ── i2c (DDC/CI for external monitors) ───────────────
  hardware.i2c.enable = true;

  # ── Stylix (global theming — gruvbox) ─────────────────
  stylix = {
    enable = true;
    image = ./wallpaper.png;
    polarity = "dark";
    # Explicit scheme — the current wallpaper is near-monochrome dark, so
    # Stylix's image-derived palette collapses to a narrow band (text ends
    # up dark-on-dark, icons invisible). Swap to a more colourful wallpaper
    # and remove this line to let the palette track the image again.
    base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-medium.yaml";

    fonts = {
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.nerd-fonts.jetbrains-mono;
        name = "JetBrainsMono Nerd Font Mono";
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

  system.stateVersion = "26.05";
}
