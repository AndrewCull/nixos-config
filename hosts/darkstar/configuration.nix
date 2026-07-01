{ config, pkgs, lib, ... }:

{
  networking.hostName = "darkstar";

  # The RD320U runs at native 4K, niri scale 1.0 (pixel-perfect). Bump the
  # stylix font sizes ~25% over the shared defaults so text keeps the physical
  # size it had at the old scale 1.25. Scoped here so p14s is unaffected.
  # (waybar / rofi / mako / ghostty are bumped per-host in their home modules.)
  stylix.fonts.sizes = lib.mkForce {
    applications = 13;
    desktop = 13;
    popups = 20;
    terminal = 14;
  };
  # Cursor likewise scales with output scale. At scale 1.0 the old size (18 →
  # ~23px effective at scale 1.25) renders at a literal 23px, which is too small
  # on a 32" 4K panel — bump to 32 for a comfortable pointer.
  stylix.cursor.size = lib.mkForce 32;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # ── CPU (Ryzen 9000 / Granite Ridge) ──────────────────
  hardware.cpu.amd.updateMicrocode = true;
  boot.kernelParams = [ "amd_pstate=active" ];

  # ── GPU (RX 9070 discrete + Granite Ridge iGPU) ───────
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
#  hardware.amdgpu.opencl.enable = true;

  # btrfs needs this in initrd for root mount
#  boot.supportedFilesystems = [ "btrfs" ];

  # ── Steam / gaming ────────────────────────────────────
  programs.steam = {
    enable = true;
    gamescopeSession.enable = true;
  };
  programs.gamemode.enable = true;

  # mesa-demos → glxinfo (OpenGL renderer/version), vulkan-tools → vulkaninfo.
  environment.systemPackages = with pkgs; [ openrgb mesa-demos vulkan-tools ];

  # ── GPU RGB control ───────────────────────────────────
  # Profiles edited in the openrgb GUI land in ~/.config/OpenRGB; sync them
  # to /var/lib/OpenRGB on every rebuild so the service can load them.
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd";
    startupProfile = "Simple";
  };
  system.activationScripts.openrgbProfiles.text = ''
    if [ -d /home/andrew/.config/OpenRGB ]; then
      mkdir -p /var/lib/OpenRGB
      cp -f /home/andrew/.config/OpenRGB/*.orp /var/lib/OpenRGB/ 2>/dev/null || true
    fi
  '';

  # -- Secrets --
  sops.defaultSopsFile = ../../secrets/secrets.yaml;
  sops.age.keyFile = "/var/lib/sops-nix/key.txt";

  # After re-encrypting secrets.yaml on p14s with `sops updatekeys`,
  # pull and uncomment these two lines + remove `initialPassword` below.
#  sops.secrets.andrew-password.neededForUsers = true;

  # -- User --
  users.users.andrew = {
    isNormalUser = true;
    extraGroups = [ "wheel" "video" "audio" "networkmanager" ];
    initialPassword = "changeme";
#   hashedPasswordFile = config.sops.secrets.andrew-password.path;
  };
}
