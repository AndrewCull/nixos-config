{ config, pkgs, inputs, ... }:

{
  # ── Nixpkgs ─────────────────────────────────────────────
  nixpkgs.config.allowUnfree = true;

  # ── Boot ──────────────────────────────────────────────
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Networking ────────────────────────────────────────
  networking.networkmanager.enable = true;
  networking.firewall.enable = true;

  # ── Locale ────────────────────────────────────────────
  time.timeZone = "America/Boise";
  i18n.defaultLocale = "en_US.UTF-8";

  # ── Users ─────────────────────────────────────────────
  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "audio" ];
    shell = pkgs.zsh;
  };

  # ── Nix settings ──────────────────────────────────────
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
    substituters = [ "https://ghostty.cachix.org" ];
    trusted-public-keys = [ "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns=" ];
  };

  # auto garbage collect
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
    ripgrep
    fd
    btop
    tree
    inputs.agenix.packages.${pkgs.system}.default
  ];

  # ── Zsh ───────────────────────────────────────────────
  programs.zsh.enable = true;

  # ── SSH daemon ───────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ── Security ──────────────────────────────────────────
  security.polkit.enable = true;
  security.rtkit.enable = true;

  # ── Pipewire (audio) ─────────────────────────────────
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ── Firmware ──────────────────────────────────────────
  hardware.enableAllFirmware = true;
  services.fwupd.enable = true;

  # ── Stylix (global theming) ─────────────────────────
  stylix = {
    enable = true;
    image = ./wallpaper.png;
    polarity = "dark";

    base16Scheme = {
      base00 = "121218"; # background
      base01 = "1a1a22"; # lighter bg
      base02 = "2a2a35"; # selection
      base03 = "45455a"; # comments
      base04 = "6a6a80"; # dark fg
      base05 = "c8c8d0"; # default fg
      base06 = "dcdce0"; # light fg
      base07 = "eeeeef"; # lightest fg
      base08 = "c87070"; # red (errors)
      base09 = "c89070"; # orange
      base0A = "c8b870"; # yellow (warnings)
      base0B = "70c890"; # green (success)
      base0C = "60b8b8"; # teal (accent)
      base0D = "6090c8"; # blue
      base0E = "9070c8"; # purple
      base0F = "806060"; # brown
    };

    fonts = {
      sansSerif = {
        package = pkgs.inter;
        name = "Inter";
      };
      monospace = {
        package = pkgs.jetbrains-mono;
        name = "JetBrains Mono";
      };
      sizes = {
        applications = 11;
        desktop = 11;
        popups = 14;
        terminal = 12;
      };
    };

    cursor = {
      package = pkgs.bibata-cursors;
      name = "Bibata-Modern-Classic";
      size = 22;
    };

    opacity = {
      terminal = 0.95;
      applications = 1.0;
    };
  };

  system.stateVersion = "24.11";
}
